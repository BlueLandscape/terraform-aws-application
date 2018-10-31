resource "aws_cloudfront_origin_access_identity" "main" {
}

locals {
  s3_origin_id = "S3-${var.project_name}-${var.environment}-static"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.static.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloudfront for ${var.project_name}"

  aliases = ["static.${var.domain_name}",]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags {
    project = "${var.project_name}"
    environment = "${var.environment}"
  }

    # Use certificate from us-east-1
    viewer_certificate {
        acm_certificate_arn = "${aws_acm_certificate.certificate_us.arn}"
        ssl_support_method  = "sni-only"
    }
}