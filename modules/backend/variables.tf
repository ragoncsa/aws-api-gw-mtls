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