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
      sid = "sqs-policy-doc"
      principals {
        type = "User"
        identifiers = [ "arn:aws:iam::438801865484:user/sqs_rw_user" ]
      }
      actions = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.event-collector.arn]
    }

    depends_on = [aws_sqs_queue.event-collector]
}

# resource "aws_lambda_function" "event-processor" {
#     function_name = "event-processer"
#     role = ""
# }

resource "aws_sqs_queue" "event-collector" {
  name             = "event-collector-queue"
  max_message_size = 2048
}

resource "aws_sqs_queue_policy" "event-collector-policy" {
  queue_url = aws_sqs_queue.event-collector.id
  policy = data.aws_iam_policy_document.sqs-policy-doc.json
}
