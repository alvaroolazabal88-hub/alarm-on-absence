terraform {
  required_version = ">= 1.14, <2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "s3-backend-alarm-on-absence-0263443218"
    key          = "alarm-on-absence/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}