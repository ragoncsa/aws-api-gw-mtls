resource "aws_apigatewayv2_api" "http_api" {
  name          = var.service_name
  protocol_type = "HTTP"
  disable_execute_api_endpoint = true # to ensure clients are calling only via custom domain
}

resource "aws_apigatewayv2_vpc_link" "vpc_link" {
  name               = var.service_name
  security_group_ids = var.security_groups_ids
  subnet_ids         = var.private_subnets_ids
}

resource "aws_apigatewayv2_integration" "private_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "HTTP_PROXY"
  integration_uri  = var.loadbalancer_dns

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
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = var.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  mutual_tls_authentication {
      truststore_uri = var.truststore_uri
  }
}

resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = aws_apigatewayv2_api.http_api.id
  domain_name = aws_apigatewayv2_domain_name.custom_domain.id
  stage       = aws_apigatewayv2_stage.stage.id
}