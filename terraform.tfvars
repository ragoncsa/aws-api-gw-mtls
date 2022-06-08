
service_name = "my-sample"

//AWS 
region      = "eu-central-1"
environment = "dev"

/* module networking */
vpc_cidr             = "10.0.0.0/16"
public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]    //List of Public subnet cidr range
private_subnets_cidr = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"] //List of private subnet cidr ranges

/* module apigw */
domain_name = "example.com" // <-- ADD YOUR DOMAIN HERE
certificate_arn = "arn:aws:acm:eu-central-1:111111111111:certificate/11111111-2222-3333-4444-55555555555" // <-- ADD YOUR CERT ARN HERE
truststore_uri = "s3://bucket-for-truststore/truststore.pem" // <-- ADD URI TO YOUR TRUST STORE HERE