resource "aws_security_group" "rds" {
  name   = "${var.project_name}-rds-sg"
  description = "RDS Allowed Ports"
  vpc_id = "${aws_vpc.main.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
      from_port = 5432
      to_port = 5432
      protocol = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
      from_port = 5432
      to_port = 5432
      protocol = "tcp"
      cidr_blocks = ["145.131.182.137/32"]
  }

  tags {
    Name = "${var.project_name}-rds-sg"
  }
}

resource "aws_db_subnet_group" "ecs_rds_subnet_group" {
    name = "${var.project_name}-rds-subnet-group"
    description = "RDS subnet group"
    subnet_ids  = [
        "${aws_subnet.main-public.*.id}",
        "${aws_subnet.main-private.*.id}",
    ]
}

resource "aws_db_instance" "rds_instance" {
    identifier = "${var.project_name}-rds"
    allocated_storage = "${var.rds_allocated_storage}"
    engine = "${var.rds_engine}"
    engine_version = "${var.rds_engine_version}"
    instance_class = "${var.rds_instance_class}"
    name = "db_${replace(var.project_name, "-", "_")}"
    username = "user_${replace(var.project_name, "-", "_")}"
    password = "${var.database_password}"
    vpc_security_group_ids = ["${aws_security_group.rds.id}"]
    db_subnet_group_name = "${aws_db_subnet_group.ecs_rds_subnet_group.id}"
    storage_type = "${var.rds_storage_type}"
    final_snapshot_identifier = "final-snapshot"
    skip_final_snapshot = true
    multi_az = false
    publicly_accessible = true

    tags {
        Name = "${var.project_name}-rds"
    }
}

resource "aws_route53_record" "rds" {
    zone_id = "${aws_route53_zone.internal.zone_id}"
    name = "rds.${var.project_name}-internal"
    type = "CNAME"
    records = ["${aws_db_instance.rds_instance.address}"]
    ttl = "300"
}