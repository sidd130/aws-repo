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

# data "aws_iam_policy_document" "sqs-policy-doc" {
#   version = "2012-10-17"
#   statement {
#     sid = "sqs-policy-doc"
#     actions = [
#       "sqs:ReceiveMessage",
#       "sqs:GetQueueAttributes",
#       "sqs:DeleteMessage"
#     ]
#     resources = [aws_sqs_queue.event-collector.arn]
#     principals {
#       type = "AWS"
#       identifiers = [
#         aws_lambda_function.event-processor.arn
#       ]
#     }
#   }

#   depends_on = [aws_sqs_queue.event-collector, aws_lambda_function.event-processor]
# }

# data "aws_iam_policy_document" "lambda-exec-policy-doc" {
#   version = "2012-10-17"
#   statement {
#     actions = [
#       "sts:AssumeRole"
#     ]
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["lambda.amazonaws.com"]
#     }
#   }
# }

resource "aws_lambda_function" "event-processor" {
  function_name = "event-processor"
  filename      = "sqs-lambda-s3.zip"
  handler       = "handler.py"
  runtime       = "python3.12"
  role          = aws_iam_role.event-processor-exec-role.arn

  depends_on = [
    aws_iam_role.event-processor-exec-role
  ]
}

resource "aws_iam_role" "event-processor-exec-role" {
  name = "event-processor-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "event-processor-policy" {
  name = "event-processor-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda-exec-role-policy" {
  policy_arn = aws_iam_policy.event-processor-policy.arn
  role       = aws_iam_role.event-processor-exec-role.name
}


# resource "aws_lambda_event_source_mapping" "event-processor-event-src-map" {
#   function_name    = aws_lambda_function.event-processor.function_name
#   event_source_arn = aws_sqs_queue.event-collector.arn
#   depends_on = [
#     aws_lambda_function.event-processor,
#     aws_sqs_queue.event-collector,
#     aws_sqs_queue_policy.event-collector-policy
#   ]
# }

resource "aws_sqs_queue" "event-collector" {
  name             = "event-collector-queue"
  max_message_size = 2048
}

resource "aws_sqs_queue_policy" "event-collector-policy" {
  queue_url = aws_sqs_queue.event-collector.url
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "sqs:ReceiveMessage",
          "sqs:GetQueueAttributes",
          "sqs:DeleteMessage"
        ]
        Resource = aws_sqs_queue.event-collector.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_lambda_function.event-processor.arn
          }
        }
      }
    ]
  })

  depends_on = [
    aws_sqs_queue.event-collector,
    aws_lambda_function.event-processor
  ]
}
