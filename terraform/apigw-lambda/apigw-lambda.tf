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

resource "aws_iam_role" "lambda-time-exec-role" {
  name = "lambda-time-exec-role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
  }
  EOF
}

resource "aws_lambda_function" "lambda-time" {
  function_name = "lambda-time"
  role = aws_iam_role.lambda-time-exec-role.arn
  filename = "lambda-time.zip"
  handler = "handler.lambda_handler"
  runtime = "python3.10"
}

resource "aws_apigatewayv2_api" "apigw-http-api" {
  name = "apigw-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "apigw-integration" {
  api_id = aws_apigatewayv2_api.apigw-http-api.id
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  connection_type = "INTERNET"
  integration_uri = aws_lambda_function.lambda-time.invoke_arn
}

resource "aws_apigatewayv2_route" "apigw-route" {
  api_id = aws_apigatewayv2_api.apigw-http-api.id
  route_key = "GET /time"
  target = "integrations/${aws_apigatewayv2_integration.apigw-integration.id}"
}

resource "aws_apigatewayv2_stage" "apigw-stage" {
  api_id = aws_apigatewayv2_api.apigw-http-api.id
  name = "apigw-stage"
}