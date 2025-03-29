terraform {
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.18"
    }
  }
}

provider "tailscale" {
  api_key = module.onepassword.secrets.Tailscale.API.key
}