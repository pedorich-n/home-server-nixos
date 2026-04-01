terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = ">= 3"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3"
    }
  }
}
