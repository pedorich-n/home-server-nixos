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

provider "b2" {
  application_key_id = module.onepassword.secrets.Backblaze_Terraform.API.application_key_id
  application_key    = module.onepassword.secrets.Backblaze_Terraform.API.application_key
}
