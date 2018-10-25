resource "aws_route53_zone" "internal" {
   name = "${var.project_name}-internal"
   vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route53_record" "internal-ns" {
    zone_id = "${aws_route53_zone.internal.zone_id}"
    name = "${var.project_name}-internal"
    type = "NS"
    ttl = "30"
    records = [
        "${aws_route53_zone.internal.name_servers.0}",
        "${aws_route53_zone.internal.name_servers.1}",
        "${aws_route53_zone.internal.name_servers.2}",
        "${aws_route53_zone.internal.name_servers.3}"
    ]
}