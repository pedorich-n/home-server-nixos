locals {
  base_urls = {
    prowlarr    = "https://prowlarr.${var.server_domain}"
    sonarr      = "https://sonarr.${var.server_domain}"
    radarr      = "https://radarr.${var.server_domain}"
    qbittorrent = "https://qbittorrent.${var.server_domain}/api/v2"
    sabnzbd     = "https://sabnzbd.${var.server_domain}/api"
  }

  download_clients = {
    sabnzbd = {
      enable   = true
      priority = 1
      name     = "SABnzbd"
      host     = "sabnzbd"
      port     = 8080
      api_key  = module.onepassword.secrets.SABnzbd.API.key
      use_ssl  = false
    }

    qbittorrent = {
      enable   = true
      priority = 1
      name     = "qBittorrent"
      host     = "gluetun"
      port     = 8080
      use_ssl  = false
    }
  }

  forwarded_vpn_port = tonumber(nonsensitive(module.onepassword.secrets.AirVPN.WireGuard.forwarded_port))
}
