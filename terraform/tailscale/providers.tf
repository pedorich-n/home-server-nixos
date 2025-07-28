terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.18"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2"
    }
  }

  backend "s3" {
    key = "homelab/tailscale/terraform.tfstate"
  }
}

provider "tailscale" {
  api_key = module.onepassword.secrets.Tailscale.API.key
}
