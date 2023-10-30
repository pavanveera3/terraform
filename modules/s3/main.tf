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
#  lifecycle {
#    prevent_destroy = false
#  }
force_destroy=true
}



resource "aws_s3_bucket_public_access_block" "input_bucket_public_access_block" {
  bucket = aws_s3_bucket.input_bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
/*
resource "null_resource" "destroy_bucket" {
  depends_on = [aws_s3_bucket.input_bucket]

  provisioner "local-exec" {
    command = "terraform destroy -force s3://${var.bucket_name}"
    when = "destroy"
  }
}*/
