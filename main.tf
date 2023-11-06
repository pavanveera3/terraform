terraform {

#required_version = ">= 0.12.24"

backend "s3" {}


}


provider "aws" {
  region = var.region
}
/*
module "sagemaker_domain" {
  source    = "./modules/sagemaker"
    region    = var.region
    vpc_id    = var.vpc_id
    subnet_id = var.subnet_id
    sagemaker_domain = var.sagemaker_domain
    sagemaker_username = var.sagemaker_username
}
*/

module "s3_bucket" {
  source = "./modules/s3"
  bucket_name = var.bucket_name
  region      = var.region
}

/*
module "lambda_function" {
  source      = "./modules/lambda"
  region      = var.region
  account_id  = var.account_id
  bucket_arn =  module.s3_bucket.bucket_arn
  bucket_name = var.bucket_name
  function_name = var.function_name
}

 module "s3_buckets" {
   source = "./modules/s3_buckets"
   bucket_name = var.source_bucket_name
   target_bucket_name = var.target_bucket_name
   lambda_fun1=var.lambda_fun1
   lambda_fun2=var.lambda_fun2
   lambda_fun3=var.lambda_fun3
   region      = var.region
 }

 module "cross_lambda" {
   source = "./modules/cross_lambda"
   bucket_arn = module.s3_buckets.source_id
   target_bucket_arn = module.s3_buckets.target_id
   bucket_name = var.source_bucket_name
   target_bucket_name = var.target_bucket_name
   lambda_fun1=var.lambda_fun1
   lambda_fun2=var.lambda_fun2
   lambda_fun3=var.lambda_fun3
   region      = var.region
   account_id=var.account_id
 }



 module "amplify" {
   source      = "./modules/amplify"
   region      = var.region
 } 




 module "athena" {
   source      = "./modules/athena"
   region      = var.region
 }



 module "cognito" {
   source      = "./modules/cognito"
   region      = var.region
 }


 module "aws_grafana" {
   source      = "./modules/aws_grafana"
   region      = var.iot_region
   user_id     = var.user_id
   aws_grafana_workspace = var.aws_grafana_workspace
   account_id=var.account_id
 }

module "vpc" {
  source      = "./modules/vpc"
  region      = var.region
}

module "grafana" {
  source      = "./modules/grafana"
  region      = var.region
  vpc_id    =  module.vpc.vpc_id
  subnet_id = module.vpc.subnet_id
} 

 module "role_iot_twinmaker" {
   source      = "./modules/role_iot_twinmaker"
   region      = var.iot_region
   bucket_name = var.target_bucket_name
   account_id=var.account_id
 }
*/
