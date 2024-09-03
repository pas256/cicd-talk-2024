terraform {
  required_version = ">= 1.9"

  required_providers {
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  profile = "myprofile" # Set your AWS CLI profile name here
  region  = "us-west-2"
}
