

variable "region" {
  description = "eu-central-1"
}

variable "environment" {
  description = "The Deployment environment"
}

//Networking
variable "vpc_cidr" {
  description = "The CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list(any)
  description = "The CIDR block for the public subnet"
}

variable "private_subnets_cidr" {
  type        = list(any)
  description = "The CIDR block for the private subnet"
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
