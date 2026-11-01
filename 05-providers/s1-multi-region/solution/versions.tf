terraform {
  required_version = "~> 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = { Project = "tf-adv-practice" }
  }
}

provider "aws" {
  alias  = "dr"
  region = "us-west-2"

  default_tags {
    tags = { Project = "tf-adv-practice" }
  }
}
