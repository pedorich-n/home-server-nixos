terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.6.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2"
    }
  }

  backend "s3" {
    key = "homelab/minio/terraform.tfstate"
  }
}

provider "minio" {
  minio_server   = "storage.${var.server_domain}"
  minio_ssl      = true
  minio_user     = module.onepassword.secrets.Minio.Root_Credentials.user
  minio_password = module.onepassword.secrets.Minio.Root_Credentials.password
}
