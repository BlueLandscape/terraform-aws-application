resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = "${file("terraform-aws-application/policies/task-execution-assume-role.json")}"
}


resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name     = "${var.project_name}-ecs-task-execution-role-policy"
  policy   = "${file("terraform-aws-application/policies/task-execution-role-policy.json")}"
  role     = "${aws_iam_role.ecs_task_execution_role.id}"
}

