locals {
  base_urls = {
    prowlarr    = "https://prowlarr.${var.local_domain}"
    sonarr      = "https://sonarr.${var.local_domain}"
    radarr      = "https://radarr.${var.local_domain}"
    lidarr      = "https://lidarr.${var.local_domain}"
    qbittorrent = "https://qbittorrent.${var.local_domain}/api/v2"
    sabnzbd     = "https://sabnzbd.${var.local_domain}/api"
  }

  download_clients = {
    sabnzbd = {
      enable   = true
      priority = 1
      name     = "SABnzbd"
      host     = "sabnzbd.${var.local_domain}"
      port     = 443
      api_key  = module.onepassword.secrets.SABnzbd.API.key
      use_ssl  = true
    }

    qbittorrent = {
      enable   = true
      priority = 1
      name     = "qBittorrent"
      host     = "qbittorrent.${var.local_domain}"
      port     = 443
      use_ssl  = true
    }
  }

  forwarded_vpn_port = tonumber(nonsensitive(module.onepassword.secrets.AirVPN.WireGuard.forwarded_port))
}
