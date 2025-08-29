terraform {
  required_providers {
    prowlarr = {
      source  = "devopsarr/prowlarr"
      version = "~> 3.0.2"
    }

    sonarr = {
      source  = "devopsarr/sonarr"
      version = "~> 3.4.0"
    }

    radarr = {
      source  = "devopsarr/radarr"
      version = "~> 2.3.2"
    }
  }
}