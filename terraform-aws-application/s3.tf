# Private s3 bucket for static files
# Cloudfront will read from this bucket
resource "aws_s3_bucket" "static" {
  bucket = "${var.project_name}-${var.environment}-static"
  acl    = "private"
}

