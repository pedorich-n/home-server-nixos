locals {
  default_headers = {
    "Content-Type" = "application/x-www-form-urlencoded"
  }

  default_response_codes = ["200"]

  categories = toset(["movies", "audiobooks", "prowlarr", "tv"])

  preferences = {
    bypass_auth_subnet_whitelist         = "0.0.0.0/0"
    bypass_auth_subnet_whitelist_enabled = true
    bypass_local_auth                    = true

    auto_tmm_enabled  = true
    temp_path_enabled = true

    save_path = "/data/downloads/torrent/complete"
    temp_path = "/data/downloads/torrent/incomplete"

    excluded_file_names = join("\n", ["*.lnk"])

    dht            = false
    pex            = false
    lsd            = false
    anonymous_mode = false

    max_ratio        = 2
    queueing_enabled = true

    max_active_downloads = 2
    max_active_uploads   = 50
    max_active_torrents  = 100

    dont_count_slow_torrents       = true
    slow_torrent_dl_rate_threshold = 500
    slow_torrent_ul_rate_threshold = 100
    slow_torrent_inactive_timer    = 60

    autorun_enabled = true
    autorun_program = "/opt/scripts/auto_unrar.sh \"%R\""

    status_bar_external_ip = true
  }
}
