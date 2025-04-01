variable aws_region {
    type = string
    default = "ap-south-1"
    description = "AWS Region"
}

variable "s3_bucket_name" {
    type = string
    default = "pic-storage-20250401"
    description = "S3 Bucket name"
}