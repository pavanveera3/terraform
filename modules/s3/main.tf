provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region where the resources will be created."
}

variable "bucket_name" {
  description = "Name of the S3 bucket."
}

resource "aws_s3_bucket" "input_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "input_bucket_public_access_block" {
  bucket = aws_s3_bucket.input_bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

