resource "sonarr_root_folder" "root" {
  path = "/data/media/tv"
}

# See https://trash-guides.info/Sonarr/Sonarr-recommended-naming-scheme/
# Using Jellyfin TVDB recommendation
resource "sonarr_naming" "naming" {
  rename_episodes            = true
  replace_illegal_characters = true
  colon_replacement_format   = 4 # Smart
  multi_episode_style        = 5 # Prefixed Range

  standard_episode_format = local.naming_trash.episodes.standard.default
  daily_episode_format    = local.naming_trash.episodes.daily.default
  anime_episode_format    = local.naming_trash.episodes.anime.default
  series_folder_format    = local.naming_trash.series["jellyfin-tvdb"]
  season_folder_format    = local.naming_trash.season.default
  specials_folder_format  = "Specials"
}

resource "sonarr_quality_definition" "trash" {
  for_each       = local.quality_definitions_trash_mapped
  title          = each.value.title
  id             = each.value.id
  min_size       = each.value.min_size
  max_size       = each.value.max_size
  preferred_size = each.value.preferred_size
}

resource "sonarr_download_client_sabnzbd" "sabnzbd" {
  enable      = var.sabnzbd_download_client_fields.enable
  priority    = var.sabnzbd_download_client_fields.priority
  name        = var.sabnzbd_download_client_fields.name
  host        = var.sabnzbd_download_client_fields.host
  port        = var.sabnzbd_download_client_fields.port
  api_key     = var.sabnzbd_download_client_fields.api_key
  use_ssl     = var.sabnzbd_download_client_fields.use_ssl
  tv_category = "tv"
}

resource "sonarr_download_client_qbittorrent" "qbittorrent" {
  enable      = var.qbittorrent_download_client_fields.enable
  priority    = var.qbittorrent_download_client_fields.priority
  name        = var.qbittorrent_download_client_fields.name
  host        = var.qbittorrent_download_client_fields.host
  port        = var.qbittorrent_download_client_fields.port
  use_ssl     = var.qbittorrent_download_client_fields.use_ssl
  tv_category = "tv"
}
