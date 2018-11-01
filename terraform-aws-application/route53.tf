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

resource "aws_route53_zone" "external" {
    name = "${var.domain_name}"
}

// This Route53 record will point at our static CloudFront distribution.
resource "aws_route53_record" "static" {
    zone_id = "${aws_route53_zone.external.zone_id}"
    name    = "static.${var.domain_name}"
    type    = "A"

    alias = {
        name                   = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
        zone_id                = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
        evaluate_target_health = false
    }
}

# Public www record
resource "aws_route53_record" "www" {
    zone_id = "${aws_route53_zone.external.zone_id}"
    name    = "www.${var.domain_name}"
    type    = "A"

    alias {
        name                   = "${aws_alb.main.dns_name}"
        zone_id                = "${aws_alb.main.zone_id}"
        evaluate_target_health = true
    }
}

# Public no www record
resource "aws_route53_record" "no_www" {
    zone_id = "${aws_route53_zone.external.zone_id}"
    name    = "${var.domain_name}"
    type    = "A"

    alias {
        name                   = "${aws_alb.main.dns_name}"
        zone_id                = "${aws_alb.main.zone_id}"
        evaluate_target_health = true
    }
}

# Google site text validation
resource "aws_route53_record" "google_validate" {
    zone_id = "${aws_route53_zone.external.zone_id}"
    name    = "${var.domain_name}"
    type    = "TXT"
    records = ["google-site-verification=${var.google_site_verification}"]
    ttl     = "900"
}

# Google mx records for e-mail
resource "aws_route53_record" "google_mx" {
    zone_id = "${aws_route53_zone.external.zone_id}"
    name    = "${var.domain_name}"
    type    = "MX"
    ttl     = "300"

    records = [
        "20 ALT1.ASPMX.L.GOOGLE.COM",
        "20 ALT2.ASPMX.L.GOOGLE.COM",
        "30 ALT3.ASPMX.L.GOOGLE.COM",
        "10 ASPMX.L.GOOGLE.COM",
        "30 ALT4.ASPMX.L.GOOGLE.COM",
    ]
}





