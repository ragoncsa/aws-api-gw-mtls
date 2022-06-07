output "vpc_id" {
  value = module.networking.vpc_id
}

output "vpc_cidr" {
  value = module.networking.vpc_cidr
}

output "private_subnets_id" {
  value = module.networking.private_subnets_id
}

output "private_subnets_cidr" {
  value = module.networking.private_subnets_cidr
}

output "default_sg_id" {
  value = module.networking.default_sg_id
}
