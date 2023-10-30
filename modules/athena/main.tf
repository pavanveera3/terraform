provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region where the resources will be created."
}

resource "aws_athena_workgroup" "workgroup_name" {
  name = "workgroup_name"
  state = "ENABLED"
  tags = {
    GrafanaDataSource = "true"
  }
  configuration {
    enforce_workgroup_configuration = true
    result_configuration {
      output_location = "s3://ihfs-canada-testing12341"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
# resource "aws_athena_database" "database_name" {
#   name     = "data_name"
#   bucket   = "ihfs-canada-testing12341"
# }
