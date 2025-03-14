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

data "aws_iam_policy_document" "sqs-policy-doc" {
  statement {
    sid = "lambda-access-policy-doc"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "sqs:DeleteMessage"
    ]
    resources = [aws_sqs_queue.event-collector.arn]
    principals {
      type        = "AWS"
      identifiers = [aws_lambda_function.event-processor.arn]
    }
  }

  depends_on = [aws_sqs_queue.event-collector, aws_lambda_function.event-processor]
}

data "aws_iam_policy_document" "lambda-exec-policy-doc" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "sqs:DeleteMessage"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "event-processor-exec-role" {
  name               = "event-processor-exec-role"
  assume_role_policy = data.aws_iam_policy_document.lambda-exec-policy-doc.json
}

resource "aws_lambda_function" "event-processor" {
  function_name = "event-processer"
  filename      = "sqs-lambda-s3.zip"
  handler       = "handler.py"
  runtime       = "python3.12"
  role          = aws_iam_role.event-processor-exec-role.arn

  depends_on = [aws_sqs_queue.event-collector, aws_iam_role.event-processor-exec-role]
}

resource "aws_lambda_event_source_mapping" "event-processor-event-src-map" {
  function_name    = aws_lambda_function.event-processor.arn
  event_source_arn = aws_sqs_queue.event-collector.arn
  depends_on       = [aws_lambda_function.event-processor, aws_sqs_queue.event-collector]
}

resource "aws_sqs_queue" "event-collector" {
  name             = "event-collector-queue"
  max_message_size = 2048
}

# resource "aws_sqs_queue_policy" "event-collector-policy" {
#   queue_url = aws_sqs_queue.event-collector.id
#   policy    = data.aws_iam_policy_document.sqs-policy-doc.json
# }
