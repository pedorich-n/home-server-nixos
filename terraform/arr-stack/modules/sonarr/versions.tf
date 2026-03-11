terraform {
  required_providers {
    sonarr = {
      source  = "devopsarr/sonarr"
      version = "~> 3"
    }

    terracurl = {
      source  = "devops-rob/terracurl"
      version = "~> 2"
    }
  }
}