######
##
## VARIABLES
## 
######
variable "stack_name" {
  description = "The name prefix to be given to all created resources"
  default     = "purge-aws"
}

variable "config_file" {
  description = "AWS Nuke config file to be used during purge execution"
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
resource "random_uuid" "suffix" {
}

resource "aws_s3_bucket" "purge_bucket" {
  bucket = "${var.stack_name}-config-${random_uuid.suffix.result}"
}

resource "aws_s3_object" "purge_config" {
  bucket = aws_s3_bucket.purge_bucket.id
  key = "purge_config"
  source = var.config_file
  etag = filemd5(var.config_file)
}

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
    "image": "ghcr.io/jpbarto/purge-aws:latest",
    "cpu": 1024,
    "memory": 2048,
    "essential": true,
    "environment": [
        {
            "name": "AWS_NUKE_DELETE",
            "value": "false"
        },
        {
            "name": "AWS_NUKE_CONFIG_BUCKET",
            "value": "${aws_s3_bucket.purge_bucket.id}"
        },
        {
            "name": "AWS_NUKE_CONFIG_KEY",
            "value": "purge_config"
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


