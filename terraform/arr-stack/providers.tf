terraform {
  backend "s3" {
    key = "homelab/arr-stack/terraform.tfstate"
  }
}