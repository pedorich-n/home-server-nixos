terraform {
  backend "s3" {
    key = "homelab/minio/terraform.tfstate"
  }
}