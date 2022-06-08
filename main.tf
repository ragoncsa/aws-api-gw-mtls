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

module "backend" {
  source = "./modules/backend"

  service_name = var.service_name

  security_groups_ids = module.networking.security_groups_ids
  private_subnets_ids = module.networking.private_subnets_id[0]
  vpc_id = module.networking.vpc_id
}

module "apigw" {
  source = "./modules/apigw"

  service_name = var.service_name

  security_groups_ids = module.networking.security_groups_ids
  private_subnets_ids = module.networking.private_subnets_id[0]
  vpc_id = module.networking.vpc_id
  loadbalancer_dns = module.backend.loadbalancer_dns

  domain_name = local.domain_name
  certificate_arn = local.certificate_arn
  truststore_uri = local.truststore_uri
}