variable "service_name" {
  description = "An identifier to use for various resources."
}

variable "security_groups_ids" {
  type        = list
  description = "Security groups to use for the load balancer."
}

variable "private_subnets_ids" {
  type        = list
  description = "Private subnets to deploy the service and the load balancer to."
}

variable "vpc_id" {
  description = "The VPC to use."
}

variable "loadbalancer_dns" {
  description = "The DNS of the loadbalancer."
}

variable "domain_name" {
  description = "The domain name we publish the API on"
}

variable "certificate_arn" {
  description = "The ARN of the custom domain's certificate in ACM. See: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-custom-domain-names.html#http-api-custom-domain-names-certificates"
}

variable "truststore_uri" {
  description = "The URI of the truststore to verify client certificates for mTLS. See: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-mutual-tls.html#http-api-mutual-tls-prerequisites"
}
