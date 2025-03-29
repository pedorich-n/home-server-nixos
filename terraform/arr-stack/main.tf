locals {
  base_urls = {
    prowlarr    = "http://prowlarr.${var.server_domain}"
    sonarr      = "http://sonarr.${var.server_domain}"
    radarr      = "http://radarr.${var.server_domain}"
    qbittorrent = "http://qbittorrent.${var.server_domain}/api/v2"
  }
}

module "onepassword" {
  source = "../modules/onepassword"
  items  = ["Prowlarr", "Prowlarr_Indexers", "Sonarr", "Radarr", "SABnzbd"]
}

module "arr_stack_shared" {
  source          = "./modules/arr-shared"
  sabnznd_api_key = module.onepassword.secrets.SABnzbd.API.key
}

module "qbittorrent" {
  source   = "./modules/qbittorrent"
  base_url = local.base_urls.qbittorrent
}

module "prowlarr" {
  source                             = "./modules/prowlarr"
  indexer_credentials                = module.onepassword.secrets.Prowlarr_Indexers
  base_url                           = local.base_urls.prowlarr
  prowlarr_api_key                   = module.onepassword.secrets.Prowlarr.API.key
  radarr_api_key                     = module.onepassword.secrets.Radarr.API.key
  sonarr_api_key                     = module.onepassword.secrets.Sonarr.API.key
  sabnzbd_download_client_fields     = module.arr_stack_shared.sabnznd_download_client
  qbittorrent_download_client_fields = module.arr_stack_shared.qbittorrent_download_client
}

module "radarr" {
  source                             = "./modules/radarr"
  base_url                           = local.base_urls.radarr
  radarr_api_key                     = module.onepassword.secrets.Radarr.API.key
  sabnzbd_download_client_fields     = module.arr_stack_shared.sabnznd_download_client
  qbittorrent_download_client_fields = module.arr_stack_shared.qbittorrent_download_client
}

module "sonarr" {
  source                             = "./modules/sonarr"
  base_url                           = local.base_urls.sonarr
  sonarr_api_key                     = module.onepassword.secrets.Sonarr.API.key
  sabnzbd_download_client_fields     = module.arr_stack_shared.sabnznd_download_client
  qbittorrent_download_client_fields = module.arr_stack_shared.qbittorrent_download_client
}
