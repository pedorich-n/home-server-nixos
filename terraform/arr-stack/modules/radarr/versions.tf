terraform {
  required_providers {
    radarr = {
      source  = "devopsarr/radarr"
      version = "~> 2.3.2"
    }

    terracurl = {
      source  = "devops-rob/terracurl"
      version = "~> 2.2.0"
    }
  }
}
