provider "aws" {
  region = "ca-central-1"
  alias = "ca-central-1"
}
provider "aws" {
 alias="us-east-1"
 region="us-east-1"
}
variable "region" {
  description = "AWS region where the resources will be created."
}


variable "account_id"{
description ="Account ID"
}
variable "bucket_arn" {
  description = "AWS region where the resources will be created."
}

variable "target_bucket_arn" {
  description = "AWS region where the resources will be created."
}
variable "bucket_name" {
  description = "AWS region where the resources will be created."
}

variable "target_bucket_name" {
  description = "AWS region where the resources will be created."
}

variable "lambda_fun1" {
  description = "AWS  lambda function 1"
}

variable "lambda_fun2" {
  description = "AWS lambda function 2"
}

variable "lambda_fun3" {
  description = "AWS  lambda function 3"
}


resource "aws_iam_role" "lambda_execution_ca" {
  name = "lambda_execution_role_ca"

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

resource "aws_iam_policy" "lambda_policy_ca" {
  name        = "lambda_policy_ca"
  description = "IAM policy for Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "s3:*",
          "s3-object-lambda:*",
        ]
        Effect   = "Allow"
        Resource = "${var.bucket_arn}/*"
      },
      {
        Action   = "logs:CreateLogGroup"
        Effect   = "Allow"
        Resource = "arn:aws:logs:ca-central-1:${var.account_id}:*"
      },
      {
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:ca-central-1:${var.account_id}:log-group:/aws/lambda/*"
      },
      {
        Action   =  [ "iot:*", "iotjobsdata:*", "iotthingsgraph:*" , "iotsitewise:*","sagemaker:*" ]
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_ca" {
  policy_arn = aws_iam_policy.lambda_policy_ca.arn
  role       = aws_iam_role.lambda_execution_ca.name
}

resource "aws_iam_role" "lambda_execution_us" {
  name = "lambda_execution_role_us"

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

resource "aws_iam_policy" "lambda_policy_us" {
  name        = "lambda_policy_us"
  description = "IAM policy for Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "s3:*"
        ]
        Effect   = "Allow"
        Resource = "${var.target_bucket_arn}/*"
      },
      {
        Action   = "logs:CreateLogGroup"
        Effect   = "Allow"
        Resource = "arn:aws:logs:us-east-1:${var.account_id}:*"
      },
      {
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:us-east-l:${var.account_id}:log-group:/aws/lambda/*"
      },
      {
        Action   =  [ "iot:*", "iotjobsdata:*" ,"sagemaker:*","iottwinmaker:*", ]
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_us" {
  policy_arn = aws_iam_policy.lambda_policy_us.arn
  role       = aws_iam_role.lambda_execution_us.name
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
  function_name = "${var.lambda_fun3}"
  role          = aws_iam_role.lambda_execution_ca.arn
  handler       = "env_index.lambda_handler"
  runtime       = "python3.10"
  timeout = 30
environment {
  variables = {
 "ANNOTATIONS_CONVERSION_TYPE" = "training"
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
    command = "sleep 60"
  }
}

/*
resource "aws_s3_bucket_notification" "bucket_notification" {
  depends_on   = [null_resource.wait_for_lambda_trigger]
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
  }
}
*/
data "archive_file" "lambda_function_zip_1" {
  type        = "zip"
  source_file = "${path.module}/env_index.py"
  output_path = "${path.module}/lambda_function_1.zip"
}
resource "aws_lambda_function" "lambda_function_1" {
  #provider      = aws.us-east-1
  filename      = data.archive_file.lambda_function_zip_1.output_path
  function_name = "${var.lambda_fun1}"
  role          = aws_iam_role.lambda_execution_ca.arn
  handler       = "env_index.lambda_handler"
  runtime       = "python3.10"
  timeout = 30
  layers        = [
   "arn:aws:lambda:ca-central-1:336392948345:layer:AWSSDKPandas-Python310:4",
        ]
}



resource "aws_lambda_permission" "lambda_permission_1" {
  #provider      = aws.us-east-1
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_1.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn
}

resource "null_resource" "wait_for_lambda_trigger_1" {
  depends_on   = [aws_lambda_permission.lambda_permission_1]
  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification_1" {
  #provider      = aws.us-east-1
  depends_on   = [null_resource.wait_for_lambda_trigger_1]
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function_1.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix      = "survey_response/"
    filter_suffix      = ".json"
  }
}
data "archive_file" "lambda_function_zip_2" {
  type        = "zip"
  source_file = "${path.module}/env_index.py"
  output_path = "${path.module}/lambda_function_2.zip"
}
resource "aws_lambda_function" "lambda_function_2" {
  provider      = aws.us-east-1
  filename      = data.archive_file.lambda_function_zip_2.output_path
  function_name = "${var.lambda_fun2}"
  role          = aws_iam_role.lambda_execution_us.arn
  handler       = "env_index.lambda_handler"
  runtime       = "python3.10"
  timeout       = 40
}


resource "aws_lambda_permission" "lambda_permission_2" {
  provider      = aws.us-east-1
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_2.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.target_bucket_arn
}

resource "null_resource" "wait_for_lambda_trigger_2" {
  depends_on   = [aws_lambda_permission.lambda_permission_2]
  provisioner "local-exec" {
    command = "sleep 60"
  }
}


resource "aws_s3_bucket_notification" "bucket_notification_2" {
  provider      = aws.us-east-1
  depends_on   = [null_resource.wait_for_lambda_trigger_2]
  bucket = var.target_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function_2.arn
    events              = ["s3:ObjectCreated:*"]
       filter_prefix      = "survey_response/"
    filter_suffix      = ".json"
  }
}


