terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.11.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2"
    }
  }
}
