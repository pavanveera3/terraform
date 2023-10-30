provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region where the resources will be created."
}

variable "user_id" {
  description = "Name of the user ID."
}

variable "aws_grafana_workspace" {
  description = "AWS Grafana Workspace"
}


variable "account_id" {
  description = "AWS Grafana Workspace"
}

resource "aws_iam_role" "assume" {
  name = "tf-grafana-assume"
 assume_role_policy = jsonencode({
   Version = "2012-10-17"
   Statement = [
     {
       Effect = "Allow"
       Principal = {
         Service = "grafana.amazonaws.com"
       }
       Action = "sts:AssumeRole"
       Condition = {
         StringEquals = {
           "aws:SourceAccount" = var.account_id
          }
         StringLike = {
           "aws:SourceArn" = "arn:aws:grafana:${var.region}:${var.account_id}:/workspaces/*"
         }
       }
     }
   ]
 })
}
/*
resource "aws_iam_role" "assume" {
  name = "tf-grafana-assume"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid =""
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      },
    ]
  })
}*/

resource "aws_iam_policy" "grafana_sitewise_policy"{
  name = "grafana_sitewise_policy"
  path = "/"
  description = "Allows Amazon Grafana to access SiteWise"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement: [
      {
        "Effect": "Allow",
        "Action": [
          "iotsitewise:Describe*",
          "iotsitewise:Get*",
          "iotsitewise:List*",
          "iotsitewise:Query*",
          "iotsitewise:Start*",
          "iotsitewise:Stop*"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource": [
          "arn:aws:s3:::*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetWorkGroup",
          "athena:ListWorkGroups",
          "athena:ListNamedQueries",
          "athena:ListQueryExecutions",
          "athena:StopQueryExecution"
        ],
        "Resource": [
          "arn:aws:athena:*:*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "gf_sw_policy_role" {
  name = "sitewise_attachment"
  roles= [aws_iam_role.assume.name]
  policy_arn = aws_iam_policy.grafana_sitewise_policy.arn
}

resource "aws_grafana_workspace" "workspace" {
  name        = "${var.aws_grafana_workspace}"
  account_access_type = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type = "SERVICE_MANAGED"
  role_arn = aws_iam_role.assume.arn
  data_sources = ["SITEWISE"]
}


#resource "aws_grafana_role_association" "role" {
#  role         = "ADMIN"
#  user_ids     = [var.user_id]
#  #user_ids     = ["a418e4c8-7021-7037-3a95-e613a4d530e0"]
#  workspace_id = aws_grafana_workspace.workspace.id
#}
