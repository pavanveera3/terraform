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

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
  force_destroy=true
}

resource "aws_s3_bucket_cors_configuration" "example" {
  bucket = aws_s3_bucket.s3_bucket.id
  cors_rule { 
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD", "PUT", "POST", "DELETE"]
      allowed_origins = ["*"]
      expose_headers = ["x-amz-server-side-encryption", "x-amz-request-id", "x-amz-id-2", "ETag"]
      max_age_seconds = 3000
    }
  
}

resource "aws_s3_bucket_versioning" "example_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
status = "Enabled"
  }
}

resource "aws_s3_bucket" "target_bucket" {
provider=aws.us-east-1
  bucket = var.target_bucket_name
  force_destroy=true
}


resource "aws_s3_bucket_versioning" "example_versioning_1" {
provider=aws.us-east-1
  bucket = aws_s3_bucket.target_bucket.id
  versioning_configuration {
status = "Enabled"
  }
}


resource "aws_s3_bucket_public_access_block" "target_bucket_public_access_block" {
provider=aws.us-east-1
  bucket = aws_s3_bucket.target_bucket.bucket

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "folder1_1" {
  depends_on  =[aws_s3_bucket.s3_bucket]
  bucket = var.bucket_name
  key    = "survey_csv/residential/" # Note the trailing slash to represent a folder
  content = ""
}

resource "aws_s3_object" "folder1_1a" {
  depends_on  =[aws_s3_bucket.s3_bucket]
  bucket = var.bucket_name
  key    = "survey_csv/templates/" # Note the trailing slash to represent a folder
  content = ""
}

resource "aws_s3_object" "folder1_c" {
  depends_on  =[aws_s3_bucket.s3_bucket]
  bucket = var.bucket_name
  key    = "survey_csv/commercial/" # Note the trailing slash to represent a folder
  content = ""
}
resource "aws_s3_object" "folder2_1" {
provider=aws.us-east-1
  depends_on  =[aws_s3_bucket.target_bucket]
  bucket = var.target_bucket_name
  key    = "3d_model/" # Note the trailing slash to represent a folder
  content = ""
}

resource "aws_s3_object" "folder1" {
  depends_on  =[aws_s3_bucket.s3_bucket]
  bucket = var.bucket_name
  key    = "survey_response/" # Note the trailing slash to represent a folder
  content = ""
}

resource "aws_s3_object" "folder2_a" {
  depends_on  =[aws_s3_bucket.s3_bucket]
  bucket = var.bucket_name
  key    = "athena_ihfs_output/" # Note the trailing slash to represent a folder
  content = ""
}
resource "aws_s3_object" "folder2" {
  depends_on  =[aws_s3_bucket.s3_bucket]
  bucket = var.bucket_name
  key    = "ml_model_data/" # Note the trailing slash to represent a folder
  content = ""
}
resource "aws_s3_bucket_public_access_block" "input_bucket_public_access_block" {
  bucket = aws_s3_bucket.s3_bucket.bucket

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_iam_role" "example_role" {
  name = "s3-replication-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "example_policy" {
  name   = "example-policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetReplicationConfiguration",
                "s3:GetObjectVersionForReplication",
                "s3:GetObjectVersionAcl",
                "s3:GetObjectVersionTagging",
                "s3:GetObjectRetention",
                "s3:GetObjectLegalHold"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.s3_bucket.id}",
                "arn:aws:s3:::${aws_s3_bucket.s3_bucket.id}/*",
                "arn:aws:s3:::${aws_s3_bucket.target_bucket.id}",
                "arn:aws:s3:::${aws_s3_bucket.target_bucket.id}/*"
            ]
        },
        {
            "Action": [
                "s3:ReplicateObject",
                "s3:ReplicateDelete",
                "s3:ReplicateTags",
                "s3:ObjectOwnerOverrideToBucketOwner"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.s3_bucket.id}/*",
                "arn:aws:s3:::${aws_s3_bucket.target_bucket.id}/*"
            ]
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "example_attachment" {
  policy_arn = aws_iam_policy.example_policy.arn
  role       = aws_iam_role.example_role.name
}


resource "aws_s3_bucket_replication_configuration" "replication_configuration" {
depends_on=[aws_s3_bucket_versioning.example_versioning_1,aws_s3_bucket_versioning.example_versioning]
  role = aws_iam_role.example_role.arn
  bucket=aws_s3_bucket.s3_bucket.id
  rule {
    id      = "rule-1"
    status  = "Enabled"
    priority = 1
    destination {
      bucket        = aws_s3_bucket.target_bucket.arn
      storage_class = "STANDARD"
    }
filter{
      tag {
key="replication"
value="true"
      }
}
delete_marker_replication {
     status = "Disabled"
    }
  }
}



output "source_id" {
  description = "ID of the created S3 bucket"
  value       = aws_s3_bucket.s3_bucket.arn
}

output "target_id" {
  description = "ID of the created S3 bucket"
  value       = aws_s3_bucket.target_bucket.arn
}
