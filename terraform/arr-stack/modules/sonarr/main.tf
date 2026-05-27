resource "sonarr_root_folder" "root" {
  path = "/mnt/external/data-library/media/tv"
}

resource "sonarr_download_client_sabnzbd" "sabnzbd" {
  enable      = var.sabnzbd_download_client_fields.enable
  priority    = var.sabnzbd_download_client_fields.priority
  name        = var.sabnzbd_download_client_fields.name
  host        = var.sabnzbd_download_client_fields.host
  port        = var.sabnzbd_download_client_fields.port
  api_key     = var.sabnzbd_download_client_fields.api_key
  use_ssl     = var.sabnzbd_download_client_fields.use_ssl
  tv_category = "tv"
}

resource "sonarr_download_client_qbittorrent" "qbittorrent" {
  enable      = var.qbittorrent_download_client_fields.enable
  priority    = var.qbittorrent_download_client_fields.priority
  name        = var.qbittorrent_download_client_fields.name
  host        = var.qbittorrent_download_client_fields.host
  port        = var.qbittorrent_download_client_fields.port
  use_ssl     = var.qbittorrent_download_client_fields.use_ssl
  tv_category = "tv"
}

resource "sonarr_delay_profile" "default" {
  enable_usenet                       = true
  enable_torrent                      = true
  bypass_if_highest_quality           = false
  bypass_if_above_custom_format_score = false
  usenet_delay                        = 15
  torrent_delay                       = 90
  preferred_protocol                  = "usenet"
  tags                                = []
  order                               = 2147483647 # Copied from existing
}
