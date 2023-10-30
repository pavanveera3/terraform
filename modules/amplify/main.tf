variable "region" {
  description = "AWS region where the resources will be created."
}

provider "aws" {
  region = var.region  # Replace with your desired region
}



resource "aws_amplify_app" "my_amplify_app" {
  name     = "ihfs-webhosting"  # Replace with your app name
  repository = "https://github.com/mustimuhw/ihfs-frontend-poc"  # Replace with your GitHub repository URL
  build_spec = file("modules/amplify/buildspec.yml")  # Path to your buildspec.yml file
  access_token="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"
#  enable_branch_auto_build = true
}
resource "aws_amplify_branch" "main_branch" {
  app_id = aws_amplify_app.my_amplify_app.id
  branch_name = "main"  # Replace with your desired branch
enable_auto_build = true
}

output "amplify_app_url" {
  value = aws_amplify_app.my_amplify_app.default_domain
}

