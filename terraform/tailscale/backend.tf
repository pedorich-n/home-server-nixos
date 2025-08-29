terraform {
  backend "s3" {
    key = "homelab/tailscale/terraform.tfstate"
  }
}