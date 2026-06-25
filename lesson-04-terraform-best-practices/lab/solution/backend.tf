terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "prod/web-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
