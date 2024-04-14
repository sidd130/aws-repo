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
    region = var.aws_region  
}

# Resource definition for Lambda execution role
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

# Resource definition for Lambda function
resource "aws_lambda_function" "lambda-time" {
  function_name = "lambda-time"
  role = aws_iam_role.lambda-time-exec-role.arn
  filename = "lambda-time.zip"
  handler = "handler.lambda_handler"
  runtime = "python3.10"
  logging_config {
    log_format = "Text"
    log_group = aws_cloudwatch_log_group.lambda-log-group.id
  }
  depends_on = [ aws_cloudwatch_log_group.lambda-log-group ]
}

# Resource definition for Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "lambda-log-group" {
  name = "/aws/lambda/${aws_lambda_function.lambda-time.function_name}"
  retention_in_days = 14
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
      aws_cloudwatch_log_group.lambda-log-group.arn
    ]
  }
}

resource "aws_iam_policy" "lambda-enable-logging-policy" {
  name = "lambda-enable-logging-policy"
  policy = data.aws_iam_policy_document.lambda-logging-policy-document
}

# Attaching policy to exec role
resource "aws_iam_role_policy_attachment" "lambda-enable-logging-role-policy-attachment" {
  role = aws_iam_role.lambda-time-exec-role.name
  policy_arn = aws_iam_policy.lambda-enable-logging-policy.arn
}

# Resource definition for API Gateway HTTP API
resource "aws_apigatewayv2_api" "apigw-http-api" {
  name = "apigw-http-api"
  protocol_type = "HTTP"
}

# Resource definition for API Gateway Integration
resource "aws_apigatewayv2_integration" "apigw-integration" {
  api_id = aws_apigatewayv2_api.apigw-http-api.id
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  connection_type = "INTERNET"
  integration_uri = aws_lambda_function.lambda-time.invoke_arn
  payload_format_version = "2.0"
  response_parameters {
    status_code = 200
    mappings = {
      "append:header.Content-Type" = "application/json"
    }
  }
}

# Resource definition for API Gateway Route
resource "aws_apigatewayv2_route" "apigw-route" {
  api_id = aws_apigatewayv2_api.apigw-http-api.id
  route_key = "GET /time"
  target = "integrations/${aws_apigatewayv2_integration.apigw-integration.id}"
}

# Resource definition for API Gateway Stage
resource "aws_apigatewayv2_stage" "apigw-stage" {
  api_id = aws_apigatewayv2_api.apigw-http-api.id
  name = "apigw-stage"
}