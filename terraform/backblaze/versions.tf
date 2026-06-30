terraform {
  required_providers {
    corefunc = {
      source  = "northwood-labs/corefunc"
      version = "~> 2.2"
    }

    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.13"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3"
    }
  }
}