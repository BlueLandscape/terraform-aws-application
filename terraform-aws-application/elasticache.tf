resource "aws_security_group" "elasticache" {
  name   = "${var.project_name}-elasticache-sg"
  description = "Controls access to ElastiCache"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 1
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.project_name}-elasticache-sg"
  }
}

resource "aws_elasticache_subnet_group" "default" {
  name = "${var.project_name}-elasticache-subnet-group"
  description = "ElastiCache subnet group"
  subnet_ids = [
    "${aws_subnet.main-public.*.id}"
  ]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id = "${var.project_name}"
  engine = "redis"
  engine_version = "${var.elasticache_engine_version}"
  maintenance_window = "${var.elasticache_maintenance_window}"
  node_type = "${var.elasticache_instance_type}"
  num_cache_nodes = "1"
  parameter_group_name = "default.redis2.8"
  port = "6379"
  subnet_group_name = "${aws_elasticache_subnet_group.default.name}"
  security_group_ids = ["${aws_security_group.elasticache.id}"]

  tags {
    Name = "${var.project_name}-redis"
  }
}

resource "aws_route53_record" "redis" {
    zone_id = "${aws_route53_zone.internal.zone_id}"
    name = "redis.${var.project_name}-internal"
    type = "CNAME"
    records = ["${aws_elasticache_cluster.redis.cache_nodes.0.address}"]
    ttl = "300"
}