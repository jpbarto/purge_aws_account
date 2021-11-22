######
##
## VARIABLES
## 
######
variable "aws_account_id" {
  description = "The target AWS account number"
  default     = "123456789012"
}

variable "stack_name" {
  description = "The name prefix to be given to all created resources"
  default     = "wipeit"
}

########
##
## CONFIGURATION
##
########

provider "aws" {}

data "aws_region" "current" {}

########
## 
## RESOURCES
##
########
resource "aws_iam_role" "purge_role" {
  name = "${var.stack_name}-PURGERole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
            "ecs-tasks.amazonaws.com",
            "lambda.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    DO-NOT-DELETE   = "true",
    terraform-stack = "${var.stack_name}"
  }
}

resource "aws_iam_role_policy_attachment" "purge_admin_permissions" {
  role       = aws_iam_role.purge_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# purge ECS cluster
resource "aws_cloudwatch_log_group" "purge_log_group" {
  name = "/ecs/${var.stack_name}-purge-output"
  tags = {
    DO-NOT-DELETE   = "true",
    terraform-stack = "${var.stack_name}"
  }
}

resource "aws_ecr_repository" "purge_repository" {
  name                 = "${var.stack_name}-purge-image"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    DO-NOT-DELETE   = "true",
    terraform-stack = "${var.stack_name}"
  }
}

output "ecr_url" {
  value = aws_ecr_repository.purge_repository.repository_url
}

resource "aws_ecs_cluster" "purge_cluster" {
  name = "${var.stack_name}-purge-cluster"
  tags = {
    DO-NOT-DELETE   = "true",
    terraform-stack = "${var.stack_name}"
  }
}
output "purge_cluster" {
  value = aws_ecs_cluster.purge_cluster.arn
}

resource "aws_ecs_task_definition" "purge_task_def" {
  family                   = "${var.stack_name}-purge"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  task_role_arn            = aws_iam_role.purge_role.arn
  execution_role_arn       = aws_iam_role.purge_role.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "${var.stack_name}-purge-task",
    "image": "${aws_ecr_repository.purge_repository.repository_url}:latest",
    "cpu": 1024,
    "memory": 2048,
    "essential": true,
    "environment": [
        {
            "name": "TARGET_AWS_ACCOUNT_NUMBER",
            "value": "${var.aws_account_id}"
        },
        {
            "name": "PURGE_ECS_CLUSTER",
            "value": "${aws_ecs_cluster.purge_cluster.arn}"
        },
        {
            "name": "PURGE_LOG_GROUP",
            "value": "/ecs/${var.stack_name}-purge-output"
        },
        {
          "name": "PURGE_IAM_ROLE",
          "value": "${aws_iam_role.purge_role.name}"
        }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${var.stack_name}-purge-output",
          "awslogs-region": "${data.aws_region.current.name}",
          "awslogs-stream-prefix": "ecs"
        }
    }
  }
]
DEFINITION

  tags = {
    DO-NOT-DELETE   = "true",
    terraform-stack = "${var.stack_name}"
  }
}
output "task_arn" {
  value = aws_ecs_task_definition.purge_task_def.arn
}


