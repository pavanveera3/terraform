provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region where the resources will be created."
}

variable "vpc_id" {
  description = "ID of the existing VPC."
}

variable "subnet_id" {
  description = "ID of the existing subnet."
}

variable "sagemaker_domain" {
  description = "ID of the sagemaker Domain name."
}

variable "sagemaker_username" {
  description = "User ID of the sagemaker Domain."
}

data "aws_vpc" "default" {
  id = var.vpc_id
}

data "aws_subnet" "default" {
  id = var.subnet_id
}
# IAM role for SageMaker access
resource "aws_iam_role" "sagemaker_full_access" {
  name = "sagemaker_full_access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy to grant full access to SageMaker and S3 resources
resource "aws_iam_policy" "sagemaker_full_access" {
  name        = "sagemaker_full_access"
  description = "IAM policy to grant full access to SageMaker and S3 resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sagemaker:*"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "s3:*"
        Effect   = "Allow"
        Resource = "*"  # Replace with specific S3 bucket ARN(s) if you want to restrict access to specific buckets
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "sagemaker_full_access_attachment" {
  role       = aws_iam_role.sagemaker_full_access.name
  policy_arn = aws_iam_policy.sagemaker_full_access.arn
}

# SageMaker domain
resource "aws_sagemaker_domain" "my_domain" {
  domain_name = var.sagemaker_domain #data.sg_domain.default.id
  auth_mode   = "IAM"

  default_user_settings {
    execution_role = aws_iam_role.sagemaker_full_access.arn
  }

  subnet_ids = [data.aws_subnet.default.id]  # Use the default subnet dynamically
  vpc_id     = data.aws_vpc.default.id       # Use the default VPC dynamically
}

# SageMaker user profile
resource "aws_sagemaker_user_profile" "my_user_profile" {
  user_profile_name = var.sagemaker_username #data.sg_username.default.id
  domain_id         = aws_sagemaker_domain.my_domain.id
}

