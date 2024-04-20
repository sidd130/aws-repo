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

resource "aws_iam_role" "lambda-time-exec-role" {
  name               = "lambda-time-exec-role"
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

resource "aws_cloudwatch_log_group" "lambda-log-group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda-time.function_name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "lambda-time" {
  function_name = "lambda-time"
  role = aws_iam_role.lambda-time-exec-role.arn
  filename      = "lambda-time.zip"
  handler       = "handler.lambda_handler"
  runtime       = "python3.10"
  logging_config {
    log_format = "JSON"
  }
}

data "aws_iam_policy_document" "lambda-logging-policy-document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect = "Allow"
    resources = [
      "${aws_cloudwatch_log_group.lambda-log-group.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "lambda-enable-logging-policy" {
  name   = "lambda-enable-logging-policy"
  policy = data.aws_iam_policy_document.lambda-logging-policy-document.json
}

resource "aws_iam_role_policy_attachment" "lambda-enable-logging-role-policy-attachment" {
  role       = aws_iam_role.lambda-time-exec-role.name
  policy_arn = aws_iam_policy.lambda-enable-logging-policy.arn
}

resource "aws_cloudwatch_log_group" "apigw-log-group" {
  name              = "/aws/apigw/${aws_api_gateway_rest_api.apigw-lambda-rest-api.id}"
  retention_in_days = 14
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

resource "aws_api_gateway_integration" "apigw-integration" {
  rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  resource_id = aws_api_gateway_resource.apigw-lambda-rest-resource.id
  type = "AWS_PROXY"
  integration_http_method = "POST"
  http_method = aws_api_gateway_method.get-method.http_method
  uri = aws_lambda_function.lambda-time.invoke_arn
  
}

resource "aws_api_gateway_deployment" "apigw-deploy" {
  rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
}

resource "aws_api_gateway_stage" "apigw-stage" {
  rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  stage_name = "apigw-stage"
  deployment_id = aws_api_gateway_deployment.apigw-deploy.id
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw-log-group.arn
    format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.extendedRequestId"
  }
}

output "apigw-invoke-url" {
  value       = aws_api_gateway_stage.apigw-stage.invoke_url
  description = "Invocation URL of the newly created API Gateway stage"
}