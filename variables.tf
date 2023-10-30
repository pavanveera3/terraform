variable "region" {
  description = "AWS region where the resources will be created."
  default     = "ca-central-1"
}



variable "iot_region" {
  description = "AWS region where the resources will be created."
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the existing VPC."
  default     = "vpc-013c7405a3ffe2289"
}

variable "subnet_id" {
  description = "ID of the existing subnet."
  default     = "subnet-019b8f03eb171cc47"
}

variable "bucket_name" {
  description = "Name of the S3 bucket."
  default     = "1input-bucket-name12345testing"
}

variable "account_id" {
  description = "AWS account ID."
  default     = "507164136455"
}
variable "user_id" {
  description = "AWS User ID"
  default="a418e4c8-7021-7037-3a95-e613a4d530e0"
}

variable "sagemaker_domain" {
  description = "ID of the sagemaker Domain name."
  default="my-sagemaker-domain"
}

variable "sagemaker_username" {
  description = "User ID of the sagemaker Domain."
  default="my-user-profile"
}

variable "function_name" {
  description = "Lambda Function Name."
  default="function_name_lambda"
}


variable "aws_grafana_workspace" {
  description = "Grafana Workspace Name."
  default="my-grafana-ws"
}



variable "source_bucket_name" {
  description = "Bucket name"
  default     = "ihfs-canada-testing1234"
}
variable "target_bucket_name" {
  description = "Bucket name"
  default     = "ihfs-us-testing1234"
}

variable "lambda_fun1" {
  description = "Bucket name"
  default     = "ihfs-create-athena-csv-from-survey-response"
}
variable "lambda_fun2" {
  description = "Bucket name"
  default     = "ihfs-create-twinmaker-entities-from-survey-response"
}
variable "lambda_fun3" {
  description = "Bucket name"
  default     = "ihfs-convert-annotation-csv-to-json"
}

