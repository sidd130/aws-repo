terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.41"
    }
  }

  required_version = ">=1.2.0"
}

provider "aws" {
  region = "ap-south-1"
}

# resource "aws_cloudwatch_log_group" "lambda-log-group" {
#   name              = "/aws/lambda/${aws_lambda_function.lambda-time.function_name}"
#   retention_in_days = 14
# }

# data "aws_iam_policy_document" "lambda-logging-policy-document" {
#   statement {
#     actions = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents"
#     ]
#     effect = "Allow"
#     resources = [
#       "${aws_cloudwatch_log_group.lambda-log-group.arn}:*"
#     ]
#   }
# }

# resource "aws_iam_policy" "lambda-enable-logging-policy" {
#   name   = "lambda-enable-logging-policy"
#   policy = data.aws_iam_policy_document.lambda-logging-policy-document.json
# }

# resource "aws_iam_role_policy_attachment" "lambda-enable-logging-role-policy-attachment" {
#   role       = aws_iam_role.lambda-time-exec-role.name
#   policy_arn = aws_iam_policy.lambda-enable-logging-policy.arn
# }

# resource "aws_cloudwatch_log_group" "apigw-log-group" {
#   name              = "/aws/apigw/${aws_api_gateway_rest_api.apigw-lambda-rest-api.id}"
#   retention_in_days = 14
# }

# resource "aws_api_gateway_account" "apigw-account" {
#   cloudwatch_role_arn = aws_iam_role.apigw-logging.arn
# }

# REST API
resource "aws_api_gateway_rest_api" "apigw-lambda-rest-api" {
  name = "apigw-lambda-rest"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# REST API Resource
resource "aws_api_gateway_resource" "apigw-lambda-rest-resource" {
  rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  path_part   = "time"
  parent_id   = aws_api_gateway_rest_api.apigw-lambda-rest-api.root_resource_id
}

# POST Method
resource "aws_api_gateway_method" "post-method" {
  rest_api_id   = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  resource_id   = aws_api_gateway_resource.apigw-lambda-rest-resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# POST Integration
resource "aws_api_gateway_integration" "apigw-integration" {
  rest_api_id             = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  resource_id             = aws_api_gateway_resource.apigw-lambda-rest-resource.id
  http_method             = aws_api_gateway_method.post-method.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.aws_lambda_function.invoke_arn
}

# POST Method Response
resource "aws_api_gateway_method_response" "apigw-method-response" {
  rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  resource_id = aws_api_gateway_resource.apigw-lambda-rest-resource.id
  http_method = aws_api_gateway_method.post-method.http_method
  status_code = "200"

  //cors section
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# POST Integration Response
resource "aws_api_gateway_integration_response" "apigw-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  resource_id = aws_api_gateway_resource.apigw-lambda-rest-resource.id
  http_method = aws_api_gateway_method.post-method.http_method
  status_code = aws_api_gateway_method_response.apigw-method-response.status_code

  //cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  
  depends_on = [
    aws_api_gateway_method.post-method,
    aws_api_gateway_integration.apigw-integration
  ]
}

# OPTIONS Method
resource "aws_api_gateway_method" "options-method" {
  rest_api_id   = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  resource_id   = aws_api_gateway_resource.apigw-lambda-rest-resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# OPTIONS Integration
resource "aws_api_gateway_integration" "options-integration" {
  rest_api_id             = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  resource_id             = aws_api_gateway_resource.apigw-lambda-rest-resource.id
  http_method             = aws_api_gateway_method.options-method.http_method
  integration_http_method = "OPTIONS"
  type                    = "MOCK"
}

# OPTIONS Method Response
resource "aws_api_gateway_method_response" "options-method-response" {
  rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  resource_id = aws_api_gateway_resource.apigw-lambda-rest-resource.id
  http_method = aws_api_gateway_method.options-method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# OPTIONS Integration Response
resource "aws_api_gateway_integration_response" "options-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  resource_id = aws_api_gateway_resource.apigw-lambda-rest-resource.id
  http_method = aws_api_gateway_method.options-method.http_method
  status_code = aws_api_gateway_method_response.options-method-response.status_code

  depends_on = [
    aws_api_gateway_method.options-method,
    aws_api_gateway_integration.options-integration
  ]
}

# Deployment
resource "aws_api_gateway_deployment" "apigw-deploy" {
  rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
  depends_on = [
    aws_api_gateway_integration.apigw-integration,
    aws_api_gateway_integration.options-integration
  ]

  stage_name = "dev"
}

# Lambda function
resource "aws_lambda_function" "aws_lambda_function" {
  filename      = "lambda-time.zip"
  function_name = "lambda-time"
  role          = aws_iam_role.lambda-time-exec-role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.10"
  # logging_config {
  #   log_format = "JSON"
  # }
}

# Lambda IAM role
resource "aws_iam_role" "lambda-time-exec-role" {
  name = "lambda-time-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda IAM policy
resource "aws_iam_role_policy_attachment" "lambda-policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = aws_iam_role.lambda-time-exec-role.name
}

# Lambda permission
resource "aws_lambda_permission" "apigw-lambda-permission" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aws_lambda_function.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.apigw-lambda-rest-api.execution_arn}/*/*/*"
}

# resource "aws_api_gateway_stage" "apigw-stage" {
#   rest_api_id = aws_api_gateway_rest_api.apigw-lambda-rest-api.id
#   stage_name = "apigw-stage"
#   deployment_id = aws_api_gateway_deployment.apigw-deploy.id
#   # access_log_settings {
#   #   destination_arn = aws_cloudwatch_log_group.apigw-log-group.arn
#   #   format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.extendedRequestId"
#   # }
# }

# output "apigw-invoke-url" {
#   value       = aws_api_gateway_stage.apigw-stage.invoke_url
#   description = "Invocation URL of the newly created API Gateway stage"
# }
