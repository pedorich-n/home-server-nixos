terraform {
  required_providers {
    corefunc = {
      source  = "northwood-labs/corefunc"
      version = "~> 2.1.0"
    }

    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.11"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2"
    }
  }
}