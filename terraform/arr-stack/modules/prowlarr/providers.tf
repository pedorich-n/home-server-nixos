terraform {
  required_providers {
    prowlarr = {
      source  = "devopsarr/prowlarr"
      version = "~> 3.0.2"
    }
  }
}

provider "prowlarr" {
  url     = var.base_url
  api_key = var.api_key
}