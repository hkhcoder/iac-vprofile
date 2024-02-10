terraform {
  required_version = ">= 1.0.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.60.0"
    }

  }

  backend "s3" {
    bucket         = "alora-statefile"
    key            = "global/mystatefile/terraform.tfstate"
    dynamodb_table = "state-lock"
    region         = "eu-west-3"
    encrypt        = true
  }
}