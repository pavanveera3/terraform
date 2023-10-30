provider "aws" {
  region = var.region
}

variable function_name{
  description = "Lambda Function Name"
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
      },
      {
        Action   =  [ "iot:*", "iotjobsdata:*", "iotthingsgraph:*" , "iotsitewise:*" ]
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_execution.name
}

locals {
  lambda_function_code = filebase64("${path.module}/env_index.py")
}

data "archive_file" "lambda_function_zip" {
  type        = "zip"
  source_file = "${path.module}/env_index.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "lambda_function" {
  filename      = data.archive_file.lambda_function_zip.output_path
  function_name = "${var.function_name}"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "env_index.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      input_bucket_name = var.bucket_name
    }
  }
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
    command = "sleep 30"
  }
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  depends_on   = [null_resource.wait_for_lambda_trigger]
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".txt"
  }
}

resource "aws_s3_object" "sample_file" {
  depends_on   = [null_resource.wait_for_lambda_trigger_1]
  bucket = var.bucket_name
  key    = "input/sample_file.txt"
  source = "/home/vramidi/aws_complete/modules/lambda/sample_file.txt"  # Replace with the local path to the sample_file.txt file
}
