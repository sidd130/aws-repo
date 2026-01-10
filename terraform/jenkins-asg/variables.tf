variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0402e56c0a7afb78f"
}

# Variables for existing resources
variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

variable "security_group_id" {
  description = "ID of the existing security group"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the EC2 instance"
  type        = string
}

variable "eip_id" {
  description = "ID of the existing Elastic IP to associate with the EC2 instance"
  type        = string
}

variable "asg_desired_capacity" {
  description = "The desired capacity of the ASG"
  type        = number
  default     = 0
}

variable "asg_min_size" {
  description = "The minimum size of the ASG"
  type        = number
  default     = 0
}

variable "asg_max_size" {
  description = "The maximum size of the ASG"
  type        = number
  default     = 0
}