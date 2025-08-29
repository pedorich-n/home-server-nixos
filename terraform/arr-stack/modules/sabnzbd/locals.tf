locals {
  default_headers = {
    "Content-Type" = "application/x-www-form-urlencoded"
  }

  default_response_codes = ["200"]

  default_request_parameters = {
    output = "json"
    apikey = var.api_key
  }

  categories = toset(["movies", "audiobooks", "prowlarr", "tv"])

  servers = {
    Blocknews = {
      base_url    = "asnews.blocknews.net"
      connections = 60
      priority    = 10
      quota       = "2800G"
    }

    Thundernews = {
      base_url    = "secure.us.thundernews.com"
      connections = 50
      priority    = 20
      quota       = "480G"
    }
  }

  settings = {
    direct_unpack  = "1"
    download_dir   = "/data/downloads/usenet/incomplete"
    complete_dir   = "/data/downloads/usenet/complete"
    host_whitelist = "sabnzbd.${var.server_domain},sabnzbd"
  }
}
