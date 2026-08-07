module "onepassword" {
  source = "../modules/onepassword"
  items  = ["Prowlarr", "Prowlarr_Indexers", "Sonarr", "Radarr", "Lidarr", "SABnzbd", "AirVPN"]
}

# module "qbittorrent" {
#   source      = "./modules/qbittorrent"
#   base_url    = local.base_urls.qbittorrent
#   listen_port = local.forwarded_vpn_port
# }

module "radarr" {
  source                             = "./modules/radarr"
  sabnzbd_download_client_fields     = local.download_clients.sabnzbd
  qbittorrent_download_client_fields = local.download_clients.qbittorrent

  providers = {
    radarr = radarr
  }

  # depends_on = [
  #   module.qbittorrent,
  # ]
}

module "sonarr" {
  source                             = "./modules/sonarr"
  sabnzbd_download_client_fields     = local.download_clients.sabnzbd
  qbittorrent_download_client_fields = local.download_clients.qbittorrent

  providers = {
    sonarr = sonarr
  }

  # depends_on = [
  #   module.qbittorrent,
  # ]
}

module "lidarr" {
  source                             = "./modules/lidarr"
  sabnzbd_download_client_fields     = local.download_clients.sabnzbd
  qbittorrent_download_client_fields = local.download_clients.qbittorrent

  providers = {
    lidarr = lidarr
  }

  # depends_on = [
  #   module.qbittorrent,
  # ]
}

module "prowlarr" {
  source                             = "./modules/prowlarr"
  indexer_credentials                = module.onepassword.secrets.Prowlarr_Indexers
  radarr_api_key                     = module.onepassword.secrets.Radarr.API.key
  sonarr_api_key                     = module.onepassword.secrets.Sonarr.API.key
  lidarr_api_key                     = module.onepassword.secrets.Lidarr.API.key
  sabnzbd_download_client_fields     = local.download_clients.sabnzbd
  qbittorrent_download_client_fields = local.download_clients.qbittorrent
  base_urls = {
    prowlarr = local.base_urls.prowlarr
    sonarr   = local.base_urls.sonarr
    radarr   = local.base_urls.radarr
    lidarr   = local.base_urls.lidarr
  }

  providers = {
    prowlarr = prowlarr
  }

  depends_on = [
    # module.qbittorrent,
    module.radarr,
    module.sonarr,
    module.lidarr
  ]
}
