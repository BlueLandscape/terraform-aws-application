resource "aws_cloudwatch_log_group" "application" {
  name = "${var.project_name}"
}