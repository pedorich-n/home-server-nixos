locals {
  default_headers = {
    "Content-Type" = "application/x-www-form-urlencoded"
  }

  default_response_codes = ["200"]

  categories = toset(["movies", "audiobooks", "prowlarr"]) # TODO: add "tv" once possible

  preferences = {
    bypass_auth_subnet_whitelist         = "0.0.0.0/0"
    bypass_auth_subnet_whitelist_enabled = true
    bypass_local_auth                    = true

    save_path = "/data/downloads/torrent/complete"
    temp_path = "/data/downloads/torrent/incomplete"

    excluded_file_names = join("\n", ["*.lnk"])

    dht            = false
    pex            = false
    lsd            = false
    anonymous_mode = false

    max_ratio        = 2
    queueing_enabled = false
  }
}
