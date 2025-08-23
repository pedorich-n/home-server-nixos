terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.21"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2"
    }

    assert = {
      source  = "hashicorp/assert"
      version = "~> 0.16"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  backend "s3" {
    key = "homelab/tailscale/terraform.tfstate"
  }
}

provider "tailscale" {
  api_key = module.onepassword.secrets.Tailscale.API.key
}
