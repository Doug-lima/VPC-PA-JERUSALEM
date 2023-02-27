terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "vpc_terraform" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name      = "VPC Terraform"
    Owner     = "Douglas"
    CreatedAt = "2024-02-23"
  }

}