variable "lambda_func_name" {
  description = "Name of the lambda function"
  type = string
  default = "some-func"
}

variable "iam_role_name" {
  description = "Name of the Lambda execution role"
  type = string
  default = "new-lambda-role"
}

variable "region" {
  description = "AWS region"
  type = string
  default = "ap-south-1"
}