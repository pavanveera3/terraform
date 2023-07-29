provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region where the resources will be created."
}

variable "bucket_name" {
  description = "ARN of the S3 bucket"
}

variable "account_id" {
  description = "ARN of the S3 bucket"
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket"
}

resource "aws_iam_role" "lambda_execution" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "IAM policy for Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "${var.bucket_arn}/*"
      },
      {
        Action   = "logs:CreateLogGroup"
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:*"
      },
      {
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_execution.name
}

locals {
  lambda_function_code = filebase64("${path.module}/index.py")
}

data "archive_file" "lambda_function_zip" {
  type        = "zip"
  source_file = "${path.module}/index.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "lambda_function" {
  filename      = data.archive_file.lambda_function_zip.output_path
  function_name = "lambda_function_name"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn
}

resource "null_resource" "wait_for_lambda_trigger" {
  depends_on   = [aws_lambda_permission.lambda_permission]
  provisioner "local-exec" {
    command = "sleep 10"
  }
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".txt"
  }
}

data "aws_s3_objects" "source" {
  bucket = "github-tfstate-12345"
  prefix = "sample_file.txt"  # Replace with the desired key (path) of the source file
}

data "aws_s3_bucket" "destination" {
  bucket = var.bucket_name
}


resource "aws_s3_object" "tgt" {
  for_each = data.aws_s3_objects.source

  bucket = aws_s3_bucket.destination.bucket
  key    = each.value.key
  source = aws_s3_bucket_object.source[each.key].id
}


/*
data  "aws_s3_object" "file" {
  bucket = data.aws_s3_bucket.source.bucket
  key = "sample_file.txt"
}


resource "aws_s3_object" "copy" {
  bucket = data.aws_s3_bucket.destination.bucket
  key = "sample_file.txt"
  source_object_key = data.aws_s3_object.file.key
}



#resource "aws_s3_object" "sample_file" {
#  depends_on   = [aws_s3_bucket_notification.bucket_notification]
#  bucket = var.bucket_name
#  key    = "sample_file.txt"
#  source = "/home/vramidi/atask2/sample_file.txt"  # Replace with the local path to the sample_file.txt file
#}


resource "aws_s3_bucket_object" "destination_object" {
  bucket = var.bucket_name
  key    = "sample_file.txt"  # Replace with the desired key (path) for the copied file in the destination bucket

#  acl    = "private"  # Replace with the desired ACL for the copied file, e.g., "private", "public-read", etc.
}

resource "aws_s3_bucket_copy_object" "copy_object" {
  depends_on   = [aws_s3_bucket_notification.bucket_notification]
  source_bucket = "github-tfstate-12345"
  source_key    = "sample_file.txt"  # Replace with the key (path) of the file in the source bucket that you want to copy

  destination_bucket = aws_s3_bucket_object.destination_object.bucket
  destination_key    = aws_s3_bucket_object.destination_object.key
}


resource "aws_s3_bucket_object" "copy_object" {
  depends_on   = [aws_s3_bucket_notification.bucket_notification]
  bucket = var.bucket_name
  key    = "sample_file.txt"  # Replace with the desired key (path) for the copied file in the destination bucket

copy_source {
    source_bucket = "github-tfstate-12345"
    source_key    = "sample_file.txt"  # Replace with the key (path) of the file in the source bucket that you want to copy
  }

#  acl    = "private"  # Replace with the desired ACL for the copied file, e.g., "private", "public-read", etc.
}*/
