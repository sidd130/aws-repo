terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>5.41"
    }
  }

  required_version = ">=1.2.0"
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_api_gateway_rest_api" "apigw-lambda-rest-api" {
  name = "apigw-lambda-rest"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "apigw-lambda-rest-resource" {
  rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  parent_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.root_resource_id
  path_part = "time"
}

resource "aws_api_gateway_method" "get-method" {
  rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  resource_id = aws_api_gateway_resource.apigw-lambda-rest-resource.id
  http_method = "GET"
  authorization = "NONE"
}