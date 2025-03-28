locals {
  prowlarr_internal_url = "http://prowlarr:9696"
}

resource "prowlarr_sync_profile" "interactive" {
  name                      = "Interactive"
  enable_rss                = false
  enable_automatic_search   = false
  enable_interactive_search = true
  minimum_seeders           = 20
}

resource "prowlarr_sync_profile" "automatic" {
  name                      = "Automatic"
  enable_rss                = false
  enable_automatic_search   = true
  enable_interactive_search = true
  minimum_seeders           = 20
}

resource "prowlarr_application_sonarr" "sonarr" {
  name         = "Sonarr"
  sync_level   = "fullSync"
  base_url     = "http://sonarr:8989"
  prowlarr_url = local.prowlarr_internal_url
  api_key      = var.sonarr_api_key
}

resource "prowlarr_application_radarr" "radarr" {
  name         = "Radarr"
  sync_level   = "fullSync"
  base_url     = "http://radarr:7878"
  prowlarr_url = local.prowlarr_internal_url
  api_key      = var.radarr_api_key
}