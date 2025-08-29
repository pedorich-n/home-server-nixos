provider "prowlarr" {
  url     = local.base_urls.prowlarr
  api_key = module.onepassword.secrets.Prowlarr.API.key
}

provider "sonarr" {
  url     = local.base_urls.sonarr
  api_key = module.onepassword.secrets.Sonarr.API.key
}

provider "radarr" {
  url     = local.base_urls.radarr
  api_key = module.onepassword.secrets.Radarr.API.key
}
