locals {
  sabnznd_download_client = {
    enable   = true
    priority = 1
    name     = "SABnznd"
    host     = "sabnzbd"
    port     = 8080
    api_key  = var.sabnznd_api_key
    use_ssl  = false
  }

  qbittorrent_download_client = {
    enable   = true
    priority = 1
    name     = "qBittorrent"
    host     = "gluetun"
    port     = 8080
    use_ssl  = false
  }
}
