terraform {

#required_version = ">= 0.12.24"

backend "s3" {}


}


provider "aws" {
  region = var.region
}

module "sagemaker_domain" {
  source    = "./modules/sagemaker"
    region    = var.region
    vpc_id    = var.vpc_id
    subnet_id = var.subnet_id
    sagemaker_domain = var.sagemaker_domain
    sagemaker_username = var.sagemaker_username
}


module "s3_bucket" {
  source = "./modules/s3"
  bucket_name = var.bucket_name
  region      = var.region
}


module "lambda_function" {
  source      = "./modules/lambda"
  region      = var.region
  account_id  = var.account_id
  bucket_arn =  module.s3_bucket.bucket_arn
  bucket_name = var.bucket_name
  function_name = var.function_name
}


