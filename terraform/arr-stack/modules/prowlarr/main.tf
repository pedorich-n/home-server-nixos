locals {
  prowlarr_internal_url = "http://prowlarr:9696"
}

# NOTE - this requires manual import first
# tofu import module.prowlarr.prowlarr_sync_profile.standard 1
resource "prowlarr_sync_profile" "standard" {
  name                      = "Standard"
  enable_rss                = true
  enable_automatic_search   = true
  enable_interactive_search = true
  minimum_seeders           = 5
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

resource "prowlarr_download_client_sabnzbd" "sabnzbd" {
  enable   = var.sabnzbd_download_client_fields.enable
  priority = var.sabnzbd_download_client_fields.priority
  name     = var.sabnzbd_download_client_fields.name
  host     = var.sabnzbd_download_client_fields.host
  port     = var.sabnzbd_download_client_fields.port
  api_key  = var.sabnzbd_download_client_fields.api_key
  use_ssl  = var.sabnzbd_download_client_fields.use_ssl
  category = "prowlarr"
}

resource "prowlarr_download_client_qbittorrent" "qbittorrent" {
  enable   = var.qbittorrent_download_client_fields.enable
  priority = var.qbittorrent_download_client_fields.priority
  name     = var.qbittorrent_download_client_fields.name
  host     = var.qbittorrent_download_client_fields.host
  port     = var.qbittorrent_download_client_fields.port
  use_ssl  = var.qbittorrent_download_client_fields.use_ssl
  category = "prowlarr"
}
