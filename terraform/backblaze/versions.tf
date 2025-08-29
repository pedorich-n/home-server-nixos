terraform {
  required_providers {
    corefunc = {
      source  = "northwood-labs/corefunc"
      version = "~> 1.5.1"
    }

    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.10"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2"
    }
  }
}