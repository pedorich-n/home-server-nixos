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
      host     = "sabnzbd.${var.server_domain}"
      port     = 443
      api_key  = module.onepassword.secrets.SABnzbd.API.key
      use_ssl  = true
    }

    qbittorrent = {
      enable   = true
      priority = 1
      name     = "qBittorrent"
      host     = "qbittorrent.${var.server_domain}"
      port     = 443
      use_ssl  = true
    }
  }

  forwarded_vpn_port = tonumber(nonsensitive(module.onepassword.secrets.AirVPN.WireGuard.forwarded_port))
}
