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

/*====
Variables used across all modules
======*/
locals {
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}

module "networking" {
  source = "./modules/networking"

  region               = var.region
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  availability_zones   = local.availability_zones
}

resource "aws_ecr_repository" "todoEcr" {
  name = "todo-repo"
}

resource "aws_ecs_cluster" "todoCluster" {
  name = "todo-cluster"
}

data "aws_iam_policy_document" "ecs_tasks_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_tasks_execution_role" {
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_execution_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "todoServiceDef" {
  family                   = "todo-service-def"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  # Available configs: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
  cpu                = 256
  memory             = 512
  execution_role_arn = aws_iam_role.ecs_tasks_execution_role.arn
  container_definitions = jsonencode([
    {
      name  = "todo"
      image = "663360383186.dkr.ecr.eu-central-1.amazonaws.com/todo-repo:latest"


      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
  ])
}

resource "aws_lb" "todoALB" {
  name               = "todo-alb"
  internal           = true
  load_balancer_type = "application"
  #   security_groups    = [aws_security_group.lb_sg.id]
  security_groups = module.networking.security_groups_ids
  #   subnets            = [for subnet in module.networking.private_subnets_id : subnet.id]
  subnets = module.networking.private_subnets_id[0]
}

resource "aws_lb_target_group" "todoTargetGroup" {
  name        = "todo-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.networking.vpc_id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.todoALB.arn
  port              = "80"
  protocol          = "HTTP"
  #   ssl_policy        = "ELBSecurityPolicy-2016-08"
  #   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.todoTargetGroup.arn
  }
}

resource "aws_ecs_service" "todo" {
  name            = "todo"
  cluster         = aws_ecs_cluster.todoCluster.id
  task_definition = aws_ecs_task_definition.todoServiceDef.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = module.networking.private_subnets_id[0]
    security_groups = module.networking.security_groups_ids
  }
  #   iam_role        = aws_iam_role.foo.arn
  #   depends_on      = [aws_iam_role_policy.foo]

  load_balancer {
    target_group_arn = aws_lb_target_group.todoTargetGroup.arn
    container_name   = "todo"
    container_port   = 80
  }
}

resource "aws_apigatewayv2_api" "sample_http_api" {
  name          = "sample-http-api-1"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_vpc_link" "vpc_link" {
  name               = "sample-vpc-link-1"
  security_group_ids = module.networking.security_groups_ids
  subnet_ids         = module.networking.private_subnets_id[0]
}

resource "aws_apigatewayv2_integration" "sample_private_integration" {
  api_id           = aws_apigatewayv2_api.sample_http_api.id
  description      = "Example with a load balancer"
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.front_end.arn

  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.vpc_link.id
}

resource "aws_apigatewayv2_route" "sample_route" {
  api_id    = aws_apigatewayv2_api.sample_http_api.id
  route_key = "ANY /{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.sample_private_integration.id}"
}

resource "aws_apigatewayv2_stage" "simple_deploy_stage" {
  api_id      = aws_apigatewayv2_api.sample_http_api.id
  name        = "$default"
  auto_deploy = true
}
