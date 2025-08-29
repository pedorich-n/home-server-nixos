module "onepassword" {
  source = "../modules/onepassword"
  items  = ["Prowlarr", "Prowlarr_Indexers", "Sonarr", "Radarr", "SABnzbd", "SABnzbd_Servers"]
}

module "qbittorrent" {
  source   = "./modules/qbittorrent"
  base_url = local.base_urls.qbittorrent
}

module "sabnzbd" {
  source          = "./modules/sabnzbd"
  base_url        = local.base_urls.sabnzbd
  api_key         = module.onepassword.secrets.SABnzbd.API.key
  sabnzbd_servers = module.onepassword.secrets.SABnzbd_Servers
  server_domain   = var.server_domain
}

module "radarr" {
  source                             = "./modules/radarr"
  sabnzbd_download_client_fields     = local.download_clients.sabnzbd
  qbittorrent_download_client_fields = local.download_clients.qbittorrent

  providers = {
    radarr = radarr
  }

  depends_on = [
    module.qbittorrent,
    module.sabnzbd
  ]
}

module "sonarr" {
  source                             = "./modules/sonarr"
  sabnzbd_download_client_fields     = local.download_clients.sabnzbd
  qbittorrent_download_client_fields = local.download_clients.qbittorrent

  providers = {
    sonarr = sonarr
  }

  depends_on = [
    module.qbittorrent,
    module.sabnzbd
  ]
}

module "prowlarr" {
  source                             = "./modules/prowlarr"
  indexer_credentials                = module.onepassword.secrets.Prowlarr_Indexers
  radarr_api_key                     = module.onepassword.secrets.Radarr.API.key
  sonarr_api_key                     = module.onepassword.secrets.Sonarr.API.key
  sabnzbd_download_client_fields     = local.download_clients.sabnzbd
  qbittorrent_download_client_fields = local.download_clients.qbittorrent

  providers = {
    prowlarr = prowlarr
  }

  depends_on = [
    module.qbittorrent,
    module.sabnzbd,
    module.radarr,
    module.sonarr
  ]
}
