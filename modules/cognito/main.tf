variable "region" {
  description = "AWS region where the resources will be created."
}

provider "aws" {
  region = var.region  # Replace with your desired region
}



resource "aws_cognito_user_pool" "user_pool" {
  name = "my-user-pool"
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  schema {
    name = "email"
    attribute_data_type = "String"
    mutable = true
    required = true
  }

  schema {
    name = "given_name"
    attribute_data_type = "String"
    mutable = true
    required = true
  }

  schema {
    name = "family_name"
    attribute_data_type = "String"
    mutable = true
    required = true
  }
 user_attribute_update_settings {
          attributes_require_verification_before_update = [
               "email"
            ] 
        }
}


resource "aws_cognito_user_pool_client" "app_client" {
  name = "my-app-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id

 # Add callback URL
  callback_urls = ["https://jwt.io"]

  # Add OAuth grant types
  allowed_oauth_flows = ["implicit", "code"]

  # Add OpenID Connect scopes
  allowed_oauth_scopes = ["aws.cognito.signin.user.admin"]

  # Add identity providers
  supported_identity_providers = ["COGNITO"]
}

#resource "aws_cognito_user_pool_domain" "cognito_domain" {
#  domain = "my-test-1234daf"
#  user_pool_id = aws_cognito_user_pool.user_pool.id
#  # Add HostedUI status as available
#}


resource "aws_cognito_identity_pool" "identity_pool" {

  # Define supported identity providers
  allow_unauthenticated_identities = true
  identity_pool_name = "my-identity-pool"
  cognito_identity_providers {
           client_id               = "${aws_cognito_user_pool_client.app_client.id}"
           provider_name           = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
           server_side_token_check = false 
        }

}
/*
resource "aws_cognito_identity_provider" "provider_1" {
  provider_name = "my-providers-1"
  provider_type = "SAML"
  user_pool_id = aws_cognito_user_pool.user_pool.id
 provider_details = {
    "MetadataURL" = "https://example.com/saml/metadata.xml"
  }
  attribute_mapping = {
    "email" = "email"
    "given_name" = "given_name"
    "family_name" = "family_name"
  }
}
data "aws_cognito_identity_provider" "user_pool" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
}
*/
resource "aws_iam_role" "identity_pool_role" {
  name = "my-identity-pool-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_user_pool.user_pool.id
           
          },
           "ForAnyValue:StringLike" = {
           "cognito-identity.amazonaws.com:amr" = "authenticated"
           }


#,
#ForAnyValue = {
#StringLike = {
#"cognito-identity.amazonaws.com:amr" = "authenticated"
#}
#}
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "identity_pool_role_policy_1" {
  policy_arn = aws_iam_policy.identity_pool_policy_1.arn
  role       = aws_iam_role.identity_pool_role.name
}

resource "aws_iam_policy" "identity_pool_policy_1" {
  name = "identity_pool_policy_1"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cognito-identity:GetCredentialsForIdentity"
        ],
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "identity_pool_role_policy_2" {
  policy_arn = aws_iam_policy.identity_pool_policy_2.arn
  role       = aws_iam_role.identity_pool_role.name
}

resource "aws_iam_policy" "identity_pool_policy_2" {
  name = "identity_pool_policy_2"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "VisualEditor0",
        Effect = "Allow",
        Action = "sagemaker:InvokeEndpoint",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "identity_pool_role_policy_3" {
  policy_arn = aws_iam_policy.identity_pool_policy_3.arn
  role       = aws_iam_role.identity_pool_role.name
}

resource "aws_iam_policy" "identity_pool_policy_3" {
  name = "identity_pool_policy_3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "VisualEditor0",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectTagging"
        ],
        Resource = "arn:aws:s3:::ihfs-survey-data/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "identity_pool_role_policy_4" {
  policy_arn = aws_iam_policy.identity_pool_policy_4.arn
  role       = aws_iam_role.identity_pool_role.name
}

resource "aws_iam_policy" "identity_pool_policy_4" {
  name = "identity_pool_policy_4"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "VisualEditor0",
        Effect = "Allow",
        Action = [
          "sagemaker:*",
          "sagemaker:InvokeEndpoint"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "roles_attachment" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id
  roles = {
    "authenticated"   = aws_iam_role.identity_pool_role.arn
    "unauthenticated" = aws_iam_role.identity_pool_role.arn
  }
}


output "user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "app_client_id" {
  value = aws_cognito_user_pool_client.app_client.id
}

#output "cognito_domain" {
#  value = aws_cognito_user_pool_domain.cognito_domain.domain
#}
