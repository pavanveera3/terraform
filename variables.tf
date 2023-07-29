variable "region" {
  description = "AWS region where the resources will be created."
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the existing VPC."
  default     = "vpc-06cf775b711fb10f1"
}

variable "subnet_id" {
  description = "ID of the existing subnet."
  default     = "subnet-0b6355f18aa28b497"
}

variable "bucket_name" {
  description = "Name of the S3 bucket."
  default     = "input-bucket-name12345testing"
}

variable "account_id" {
  description = "AWS account ID."
  default     = "507164136455"
}

