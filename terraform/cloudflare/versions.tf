terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2"
    }
  }
}