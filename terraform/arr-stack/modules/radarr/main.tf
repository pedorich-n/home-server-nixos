resource "radarr_root_folder" "root" {
  path = "/mnt/external/data-library/media/movies"
}

resource "radarr_download_client_sabnzbd" "sabnzbd" {
  enable         = var.sabnzbd_download_client_fields.enable
  priority       = var.sabnzbd_download_client_fields.priority
  name           = var.sabnzbd_download_client_fields.name
  host           = var.sabnzbd_download_client_fields.host
  port           = var.sabnzbd_download_client_fields.port
  api_key        = var.sabnzbd_download_client_fields.api_key
  use_ssl        = var.sabnzbd_download_client_fields.use_ssl
  movie_category = "movies"
}

resource "radarr_download_client_qbittorrent" "qbittorrent" {
  enable         = var.qbittorrent_download_client_fields.enable
  priority       = var.qbittorrent_download_client_fields.priority
  name           = var.qbittorrent_download_client_fields.name
  host           = var.qbittorrent_download_client_fields.host
  port           = var.qbittorrent_download_client_fields.port
  use_ssl        = var.qbittorrent_download_client_fields.use_ssl
  movie_category = "movies"
}
