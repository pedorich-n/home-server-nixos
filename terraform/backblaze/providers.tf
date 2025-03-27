terraform {
  required_providers {
    netparse = {
      source  = "gmeligio/netparse"
      version = "~> 0.0.3"
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
