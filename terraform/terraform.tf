terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.25.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
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
##
##

