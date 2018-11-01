resource "aws_security_group" "alb" {
  name        = "${var.project_name}-ecs-alb"
  description = "Controls access to the ALB"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.project_name}-alb-sg"
  }
}


# Traffic to the ECS Cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks"
  description = "allow inbound access from the ALB only"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    protocol        = "tcp"
    from_port       = "${var.app_port}"
    to_port         = "${var.app_port}"
    security_groups = ["${aws_security_group.alb.id}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "main" {
  name            = "${var.project_name}-ecs-chat"
  subnets         = ["${aws_subnet.main-public.*.id}"]
  security_groups = ["${aws_security_group.alb.id}"]
}

resource "aws_alb_target_group" "app" {
  name        = "${var.project_name}-ecs-chat"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.main.id}"
  target_type = "ip"
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.app.id}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "front_end_https" {
	load_balancer_arn = "${aws_alb.main.id}"
	port			  =	"443"
	protocol		  =	"HTTPS"
	ssl_policy		  =	"ELBSecurityPolicy-2016-08"
	certificate_arn	  =	"${aws_acm_certificate.certificate.arn}"

	default_action {
		target_group_arn  =	"${aws_alb_target_group.app.id}"
		type			  =	"forward"
	}
}


resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.fargate_cpu}"
  memory                   = "${var.fargate_memory}"
  execution_role_arn       = "${aws_iam_role.ecs_task_execution_role.arn}"

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${var.app_image}",
    "memory": ${var.fargate_memory},
    "name": "${var.project_name}-app",
    "networkMode": "awsvpc",
   "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${var.project_name}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "ecs"
        }
    },
    "portMappings": [
      {
        "containerPort": ${var.app_port},
        "hostPort": ${var.app_port}
      }
    ],
    "environment": [
      {
        "name": "DJANGO_SETTINGS_MODULE",
        "value": "blue_landscape.settings.production"
      },
      {
        "name": "APPLICATION_RUN_TYPE",
        "value": "uwsgi"
      },
      {
        "name": "DEBUG",
        "value": "${var.application_debug}"
      },
      {
        "name": "DATABASE_TYPE",
        "value": "postgresql"
      },
      {
        "name": "DATABASE_HOST",
        "value": "rds.blue-landscape-internal"
      },
      {
        "name": "DATABASE_NAME",
        "value": "db_${replace(var.project_name, "-", "_")}"
      },
      {
        "name": "DATABASE_USER",
        "value": "user_${replace(var.project_name, "-", "_")}"
      },
      {
        "name": "DATABASE_PASSWORD",
        "value": "${var.database_password}"
      },
      {
        "name": "AWS_ACCESS_KEY_ID",
        "value": "${var.aws_access_key_id}"
      },
      {
        "name": "AWS_SECRET_ACCESS_KEY",
        "value": "${var.aws_secret_access_key}"
      },
      {
        "name": "AWS_STORAGE_BUCKET_NAME",
        "value": "${var.project_name}-${var.environment}-static"
      },
      {
        "name": "AWS_S3_CUSTOM_DOMAIN",
        "value": "static.${var.domain_name}"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-ecs-service"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.app.arn}"
  desired_count   = "${var.app_count}"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.ecs_tasks.id}"]
    subnets         = ["${aws_subnet.main-private.*.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.app.id}"
    container_name   = "${var.project_name}-app"
    container_port   = "${var.app_port}"
  }

  depends_on = [
    "aws_alb_listener.front_end",
  ]
}