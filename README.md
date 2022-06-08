# aws-api-gw-mtls

## Prerequisites

1. register a domain
2. create a certificate in ARN for your domain
3. create a bucket to serve as storage for your trust store
4. create a self-signed certificate for testing mTLS and upload it to your bucket

(For more see: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-mutual-tls.html#http-api-mutual-tls-prerequisites)

## Build the infrastructure

Edit terraform.tfvars and configure your domain, your server certificate and your trust store's location. Then

```shell
$ source get-credentials.sh
$ terraform init
$ terraform apply
```

## Additional steps to complete the setup

Configure your DNS to point to the regional endpoint AWS API Gateway provided for your custom domain. Your DNS record would looks similar to the below.

```json
{
  "name": "api.example.com.",
  "rrdata": ["d-eq52thg6w3.execute-api.eu-central-1.amazonaws.com."],
  "ttl": 300,
  "type": "CNAME"
}
```

## To test

```shell
curl -k --key key-for-mtls.pem --cert cert-for-mtls.pem https://api.example.com/
```

where `key-for-mtls.pem` is the private key you created for the client, `cert-for-mtls.pem` is the client certificate and `api.example.com` is your custom domain.
