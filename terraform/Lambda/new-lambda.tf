terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.16"
    }
  }

  required_version = ">=1.2.0"
}

resource "aws_iam_role" "new-lambda-role" {
  name               = var.iam_role_name
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

resource "aws_lambda_function" "new-lambda" {
  function_name = var.lambda_func_name
  filename      = "handler.zip"
  # runtime       = "python3.10"
  handler       = "handler.lambda_handler"
  role          = aws_iam_role.new-lambda-role.arn
}