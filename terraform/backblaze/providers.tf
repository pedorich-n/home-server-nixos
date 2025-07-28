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

  backend "s3" {
    key = "homelab/backblaze/terraform.tfstate"

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_s3_checksum            = true        # Not supported by B2
    region                      = "us-east-1" # Doesn't matter, since B2 doesn't support this setting

    endpoints = {
      s3 = "https://s3.us-east-005.backblazeb2.com"
    }
  }
}

provider "b2" {
  application_key_id = module.onepassword.secrets.Backblaze_Terraform.API.application_key_id
  application_key    = module.onepassword.secrets.Backblaze_Terraform.API.application_key
}
