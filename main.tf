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

  domain_name = var.domain_name
  certificate_arn = var.certificate_arn
  truststore_uri = var.truststore_uri
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

resource "aws_ecs_cluster" "cluster" {
  name = "my-sample"
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

resource "aws_ecs_task_definition" "servicedef" {
  family                   = "my-sample"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  # Available configs: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
  cpu                = 256
  memory             = 512
  execution_role_arn = aws_iam_role.ecs_tasks_execution_role.arn
  container_definitions = jsonencode([
    {
      name  = "my-sample"
      image = "nginx"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
  ])
}

resource "aws_lb" "loadbalancer" {
  name               = "my-sample"
  internal           = true
  load_balancer_type = "application"
  security_groups = module.networking.security_groups_ids
  subnets = module.networking.private_subnets_id[0]
}

resource "aws_lb_target_group" "target_group" {
  name        = "my-sample"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.networking.vpc_id
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = "my-sample"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.servicedef.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = module.networking.private_subnets_id[0]
    security_groups = module.networking.security_groups_ids
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "my-sample"
    container_port   = 80
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "my-sample"
  protocol_type = "HTTP"
  disable_execute_api_endpoint = true # to ensure clients are calling only via custom domain
}

resource "aws_apigatewayv2_vpc_link" "vpc_link" {
  name               = "my-sample"
  security_group_ids = module.networking.security_groups_ids
  subnet_ids         = module.networking.private_subnets_id[0]
}

resource "aws_apigatewayv2_integration" "private_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.lb_listener.arn

  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.vpc_link.id
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.private_integration.id}"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_domain_name" "custom_domain" {
  domain_name = local.domain_name

  domain_name_configuration {
    certificate_arn = local.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  mutual_tls_authentication {
      truststore_uri = local.truststore_uri
  }
}

resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = aws_apigatewayv2_api.http_api.id
  domain_name = aws_apigatewayv2_domain_name.custom_domain.id
  stage       = aws_apigatewayv2_stage.stage.id
}