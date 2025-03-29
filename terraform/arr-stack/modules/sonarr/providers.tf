terraform {
  required_providers {
    sonarr = {
      source  = "devopsarr/sonarr"
      version = "~> 3.4.0"
    }

    terracurl = {
      source  = "devops-rob/terracurl"
      version = "~> 1.2.2"
    }
  }
}

provider "sonarr" {
  url     = var.base_url
  api_key = var.sonarr_api_key
}