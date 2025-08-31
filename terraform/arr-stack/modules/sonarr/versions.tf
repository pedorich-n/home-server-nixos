terraform {
  required_providers {
    sonarr = {
      source  = "devopsarr/sonarr"
      version = "~> 3.4.0"
    }

    terracurl = {
      source  = "devops-rob/terracurl"
      version = "~> 2.1.0"
    }
  }
}