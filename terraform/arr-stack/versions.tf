terraform {
  required_providers {
    prowlarr = {
      source  = "devopsarr/prowlarr"
      version = "~> 3"
    }

    sonarr = {
      source  = "devopsarr/sonarr"
      version = "~> 3"
    }

    radarr = {
      source  = "devopsarr/radarr"
      version = "~> 2"
    }
  }
}