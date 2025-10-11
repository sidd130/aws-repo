variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for the launch configuration"
  type        = string
  default     = "ami-0402e56c0a7afb78f"
}

variable "min_size" {
  description = "Minimum size of the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the ASG"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired capacity of the ASG"
  type        = number
  default     = 1
}

# Variables for existing resources
variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID of the existing public subnet"
  type        = string
}

variable "existing_route_table_id" {
  description = "ID of the existing route table"
  type        = string
}

variable "security_group_id" {
  description = "ID of the existing security group"
  type        = string
}