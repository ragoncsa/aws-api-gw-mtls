terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

# resource "aws_ecr_repository" "todoEcr" {
#   name = "todo-repo"
# }

resource "aws_ecs_cluster" "todoCluster" {
  name = "todo-cluster"
}

resource "aws_ecs_task_definition" "todoServiceDef" {
  family = "todo-service-def"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  # Available configs: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
  cpu       = 256
  memory    = 512
  container_definitions = jsonencode([
    {
      name      = "todo"
      image     = "nginx"
      
      
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
  ])
}

# resource "aws_lb" "todoALB" {
#   name               = "todo-alb"
#   internal           = true
#   load_balancer_type = "application"
# #   security_groups    = [aws_security_group.lb_sg.id]
# #   subnets            = [for subnet in aws_subnet.public : subnet.id]
# }

# resource "aws_ecs_service" "todo" {
#   name            = "todo"
#   cluster         = aws_ecs_cluster.todoCluster.id
#   task_definition = aws_ecs_task_definition.todoServiceDef.arn
#   desired_count   = 1
# #   iam_role        = aws_iam_role.foo.arn
# #   depends_on      = [aws_iam_role_policy.foo]

#   load_balancer {
#     target_group_arn = aws_lb_target_group.foo.arn
#     container_name   = "todo"
#     container_port   = 80
#   }
# }
