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

  # backend "s3" {
  #   bucket     = var.s3_backend_bucket
  #   key        = "homelab/tailscale/terraform.tfstate"
  #   access_key = var.s3_backend_application_key_id
  #   secret_key = var.s3_backend_application_key

  #   skip_credentials_validation = true
  #   skip_region_validation      = true
  #   skip_s3_checksum            = true        # Not supported by B2
  #   region                      = "us-east-1" # Doesn't matter, since B2 doesn't support this setting

  #   endpoints = {
  #     s3 = "https://s3.us-east-005.backblazeb2.com"
  #   }
  # }
}

provider "minio" {
  minio_server   = "storage.${var.server_domain}"
  minio_ssl      = true
  minio_user     = module.onepassword.secrets.Minio.Root_Credentials.user
  minio_password = module.onepassword.secrets.Minio.Root_Credentials.password
}
