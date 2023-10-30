provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region where the resources will be created."
}


variable "bucket_name" {
  description = "Name of the S3 bucket to be used by IoT TwinMaker"
}

variable "account_id" {
  description = "Name of the S3 bucket to be used by IoT TwinMaker"
}

resource "aws_iam_role" "grafana_role" {
  name = "GrafanaRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "grafana.amazonaws.com"
        },
        Action = "sts:AssumeRole",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          },
          StringLike = {
            "aws:SourceArn" = "arn:aws:grafana:us-east-1:${var.account_id}:/workspaces/*"
          }
        }
      },
    ]
  })
}



resource "aws_iam_policy_attachment" "grafana_athena_access" {
  name       = "GrafanaAthenaAccess"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonGrafanaAthenaAccess"
  roles      = [aws_iam_role.grafana_role.name]
}

resource "aws_iam_policy_attachment" "s3_full_access" {
  name       = "S3FullAccess"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  roles      = [aws_iam_role.grafana_role.name]
}

data "aws_iam_policy_document" "iot_twinmaker_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucket",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:ListObjects",
      "s3:ListObjectsV2",
      "s3:GetBucketLocation",
      "s3:DeleteObject",
      "lambda:InvokeFunction",
      "kinesisvideo:DescribeStream",
      "iotsitewise:DescribeAssetModel",
      "iotsitewise:ListAssetModels",
      "iotsitewise:DescribeAsset",
      "iotsitewise:ListAssets",
      "iotsitewise:DescribeAssetProperty",
      "iotsitewise:GetAssetPropertyValue",
      "iotsitewise:GetAssetPropertyValueHistory"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/DO_NOT_DELETE_WORKSPACE_*",
      "arn:aws:lambda:::function:iottwinmaker-*",
      "*"
    ]
  }
}

resource "aws_iam_policy" "iot_twinmaker_policy" {
  name        = "iot-twinmaker-policy"
  policy      = data.aws_iam_policy_document.iot_twinmaker_policy.json
}

resource "aws_iam_role" "iot_twinmaker_role" {
  name               = "iot-twinmaker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iottwinmaker.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iot_twinmaker_policy_attachment" {
  policy_arn = aws_iam_policy.iot_twinmaker_policy.arn
  role       = aws_iam_role.iot_twinmaker_role.name
}


resource "aws_iam_policy" "ihfs-workspaceDashboardPolicy" {
  name        = "ihfs-workspaceDashboardPolicy"
  description = "Policy for ihfs-workspaceDashboardPolicy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iottwinmaker:Get*",
          "iottwinmaker:List*",
          "iottwinmaker:ExecuteQuery"
        ]
        Resource = [
          "arn:aws:iottwinmaker:us-east-1:${var.account_id}:workspace/ihfs-workspace",
          "arn:aws:iottwinmaker:us-east-1:${var.account_id}:workspace/ihfs-workspace/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "iottwinmaker:ListWorkspaces"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "iottwinmaker" {
  name               = "ihfs-workspaceDashboardRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          #Service = "iottwinmaker.amazonaws.com"
        #AWS     = "arn:aws:iam::201672358901:role/service-role/AmazonGrafanaServiceRole-n5IWMrDBT"
          AWS= aws_iam_role.grafana_role.arn
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ihfs-workspaceDashboardPolicy" {
  policy_arn = aws_iam_policy.ihfs-workspaceDashboardPolicy.arn
  role       = aws_iam_role.iottwinmaker.name
}


output "role_arn" {
  value = aws_iam_role.grafana_role.arn
}
