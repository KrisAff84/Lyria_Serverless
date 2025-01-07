terraform {
  required_version = "~> 1.7.0"
  required_providers {
    aws = {
      version = "~> 5.82.2"
    }
  }
  backend "s3" {
    bucket         = "lyria-terraform-state-2024"
    encrypt        = true
    dynamodb_table = "lyria-state-locks-2024"
    key            = "dns_records/terraform.tfstate"
    region         = "us-east-1"
    profile        = "kris84"
  }
}