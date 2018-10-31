# Create certificate
resource "aws_acm_certificate" "certificate" {
  domain_name       = "*.${var.domain_name}"
  validation_method = "EMAIL"
  subject_alternative_names = ["${var.domain_name}"]
}

# Define provider for creating certificates in us-east-1
provider "aws" {
  alias = "us_certificate"
  region = "us-east-1"
}

# Create certificate in us-east-1 for use with cloudfront
resource "aws_acm_certificate" "certificate_us" {
  domain_name       = "*.${var.domain_name}"
  validation_method = "EMAIL"
  subject_alternative_names = ["${var.domain_name}"]
  provider = "aws.us_certificate"
}