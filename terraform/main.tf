terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }
  backend "s3" {
    bucket = "terraform-nhsd-apim-bars"
    region = "eu-west-2"
  }
}

provider "aws" {
  profile = "jalal"
  region  = "eu-west-2"
}

provider "aws" {
  alias  = "acm_provider"
  region = "eu-west-2"
}
