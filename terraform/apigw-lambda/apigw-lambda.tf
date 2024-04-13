terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>4.16"
    }
  }

  required_version = ">=1.2.0"
}

provider "aws" {
    region = var.aws_region  
}

resource "aws_apigatewayv2_api" "apigw-http-api" {
  name = "apigw-http-api"
  protocol_type = "HTTP"
  body = jsonencode(
    {
        "openapi": "3.0.1",
        "info": {
            "title": "apigw-http-api-openapi-spec",
            "version": "1.0"
        },
        "paths": {
            "/time": {
                "get": {
                    "description": "Returns time in format dd-mon-yyyy hh24:mi:ss"
                }
            }
        }
    }
  )
}