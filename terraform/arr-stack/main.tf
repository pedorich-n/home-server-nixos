module "onepassword" {
  source = "../modules/onepassword"
  items  = ["Prowlarr", "Prowlarr_Indexers", "Sonarr", "Radarr", "SABNzbd"]
}


module "prowlarr" {
  source              = "./modules/prowlarr"
  indexer_credentials = module.onepassword.secrets.Prowlarr_Indexers
  base_url            = "http://prowlarr.server.lan" // TODO: turn into a variable
  api_key             = module.onepassword.secrets.Prowlarr.API.key
}