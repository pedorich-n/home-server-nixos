terraform {
  backend "s3" {
    key = "homelab/backblaze/terraform.tfstate"
  }
}
