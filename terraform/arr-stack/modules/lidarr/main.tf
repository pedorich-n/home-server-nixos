resource "lidarr_metadata_profile" "standard" {
  name = "Standard"
  # Data from API
  primary_album_types = [
    0, # Album
    1, # EP
    2, # Single
  ]
  secondary_album_types = [
    0,  # Studio
    1,  # Compilation
    2,  # Soundtrack
    3,  # Spokenword
    7,  # Remix
    10, # Demo
  ]

  release_statuses = [
    0, # Official
  ]
}

resource "lidarr_root_folder" "root" {
  name                    = "Music"
  quality_profile_id      = data.lidarr_quality_profile.standard.id
  metadata_profile_id     = lidarr_metadata_profile.standard.id
  monitor_option          = "none"
  new_item_monitor_option = "none"
  path                    = "/mnt/external/data-library/media/music"
}

resource "lidarr_naming" "naming" {
  rename_tracks              = true
  replace_illegal_characters = true
  standard_track_format      = "{[Release Year] }{Album CleanTitle}/{Track ArtistCleanName} - {[Release Year] }{Album CleanTitle} - {track:00} - {Track CleanTitle}"
  multi_disc_track_format    = "{[Release Year] }{Album CleanTitle}/{Medium Format}/{medium:00}/{Track ArtistCleanName} - {[Release Year] }{Album CleanTitle} - {track:00} - {Track CleanTitle}"
  artist_folder_format       = "{Artist CleanNameThe}"
}

resource "lidarr_download_client_sabnzbd" "sabnzbd" {
  enable                     = var.sabnzbd_download_client_fields.enable
  priority                   = var.sabnzbd_download_client_fields.priority
  name                       = var.sabnzbd_download_client_fields.name
  host                       = var.sabnzbd_download_client_fields.host
  port                       = var.sabnzbd_download_client_fields.port
  api_key                    = var.sabnzbd_download_client_fields.api_key
  use_ssl                    = var.sabnzbd_download_client_fields.use_ssl
  remove_completed_downloads = true
  remove_failed_downloads    = true
  music_category             = "music"
}

resource "lidarr_download_client_qbittorrent" "qbittorrent" {
  enable                     = var.qbittorrent_download_client_fields.enable
  priority                   = var.qbittorrent_download_client_fields.priority
  name                       = var.qbittorrent_download_client_fields.name
  host                       = var.qbittorrent_download_client_fields.host
  port                       = var.qbittorrent_download_client_fields.port
  use_ssl                    = var.qbittorrent_download_client_fields.use_ssl
  remove_completed_downloads = true
  music_category             = "music"
}

resource "lidarr_remote_path_mapping" "qbittorrent" {
  host        = var.qbittorrent_download_client_fields.host
  remote_path = "/data/downloads/torrent/"
  local_path  = "/mnt/external/data-library/downloads/torrent/"
}
