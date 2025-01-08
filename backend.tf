terraform {
  backend "s3" {
    bucket         = "s3prevail01"
    key            = "herron/terraform.tfstate"
    region         = "us-east-1"
    profile        = "prevailprimary8283"
    encrypt        = "true"
  }
}