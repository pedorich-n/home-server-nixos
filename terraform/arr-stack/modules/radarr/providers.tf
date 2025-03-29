terraform {
  required_providers {
    radarr = {
      source  = "devopsarr/radarr"
      version = "~> 2.3.2"
    }

    terracurl = {
      source  = "devops-rob/terracurl"
      version = "~> 1.2.2"
    }
  }
}

provider "radarr" {
  url     = var.base_url
  api_key = var.radarr_api_key
}