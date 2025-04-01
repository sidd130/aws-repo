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
  region = var.aws_region_name
}

# S3 bucket
resource "aws_s3_bucket" "pic-storage" {
  bucket        = var.s3_bucket_name
  force_destroy = true
  tags = {
    Name = "pic-storage"
  }
}

# Bucket policy document
data "aws_iam_policy_document" "bucket-policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
    resources = [
      "${aws_s3_bucket.pic-storage.arn}",
      "${aws_s3_bucket.pic-storage.arn}/*"
    ]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        "${aws_lambda_function.pic-reader.arn}"
      ]
    }
  }
}

# S3 bucket policy
resource "aws_s3_bucket_policy" "s3-bucket-policy" {
  bucket = aws_s3_bucket.pic-storage.id
  policy = data.aws_iam_policy_document.bucket-policy.json
}

# Lambda handler zip locator
data "archive_file" "lambda_handler_zip" {
  type        = "zip"
  source_file = "${path.module}/handler.py"
  output_path = "${path.module}/s3-lambda-textract.zip"
}

# Lambda function
resource "aws_lambda_function" "pic-reader" {
  function_name    = "pic-reader"
  filename         = data.archive_file.lambda_handler_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_handler_zip.output_path)
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.pic-reader-exec-role.arn
  environment {
    variables = {
        AWS_REGION = var.aws_region_name
        S3_BUCKET_NAME = var.s3_bucket_name
    }
  }
}

# Lambda exec role
resource "aws_iam_role" "pic-reader-exec-role" {
  name = "pic-reader-exec-role"
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

# Policy for Lambda exec role
resource "aws_iam_policy" "pic-reader-policy" {
  name = "pic-reader-exec-role-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          aws_lambda_function.pic-reader.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
            aws_s3_bucket.pic-storage.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]
        Resource = [
            "*"
        ]
      }
    ]
  })
}

# Attach policy to Lambda exec role
resource "aws_iam_role_policy_attachment" "pic-reader-exec-role-policy" {
  policy_arn = aws_iam_policy.pic-reader-policy.arn
  role = aws_iam_role.pic-reader-exec-role.name
}

# Event source mapping
resource "aws_lambda_event_source_mapping" "s3-lambda-linker" {
  function_name = aws_lambda_function.pic-reader.arn
  event_source_arn = aws_s3_bucket.pic-storage.arn
  enabled = true
}