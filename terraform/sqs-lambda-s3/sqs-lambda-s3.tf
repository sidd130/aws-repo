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
      type = "AWS"
      identifiers = [ aws_lambda_function.event-processor.arn ]
    }
  }

  depends_on = [aws_sqs_queue.event-collector]
}

data "aws_iam_policy_document" "lambda-exec-policy-doc" {
  statement {
    sid = "lambda-auth-policy-doc"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [ "lambda.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "event-collector-exec-role" {
    name = "event-collector-exec-role"
    assume_role_policy = data.aws_iam_policy_document.lambda-exec-policy-doc.json
}

resource "aws_lambda_function" "event-processor" {
  function_name = "event-processer"
  filename      = "sqs-lambda-s3.zip"
  handler       = "handler.py"
  runtime       = "python3.12"
  role          = aws_iam_role.event-collector-exec-role.arn

  depends_on = [aws_sqs_queue.event-collector]
}

resource "aws_lambda_event_source_mapping" "event-processor-event-src-map" {
  function_name = aws_lambda_function.event-processor.arn
  event_source_arn = aws_sqs_queue.event-collector.arn
}

resource "aws_sqs_queue" "event-collector" {
  name             = "event-collector-queue"
  max_message_size = 2048
}

resource "aws_sqs_queue_policy" "event-collector-policy" {
  queue_url = aws_sqs_queue.event-collector.id
  policy    = data.aws_iam_policy_document.sqs-policy-doc.json
}
