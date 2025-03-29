resource "radarr_root_folder" "root" {
  path = "/data/media/movies"
}

# See https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/#jellyfin
# Using Jellyfin TMDB recommendation
resource "radarr_naming" "naming" {
  rename_movies              = true
  replace_illegal_characters = true
  colon_replacement_format   = "smart"
  standard_movie_format      = local.naming_trash.file["jellyfin-tmdb"]
  movie_folder_format        = local.naming_trash.folder["jellyfin-tmdb"]
}

resource "radarr_quality_definition" "trash" {
  for_each       = local.quality_definitions_trash_mapped
  title          = each.value.title
  id             = each.value.id
  min_size       = each.value.min_size
  max_size       = each.value.max_size
  preferred_size = each.value.preferred_size
}

resource "radarr_download_client_sabnzbd" "sabnzbd" {
  enable         = var.sabnzbd_download_client_fields.enable
  priority       = var.sabnzbd_download_client_fields.priority
  name           = var.sabnzbd_download_client_fields.name
  host           = var.sabnzbd_download_client_fields.host
  port           = var.sabnzbd_download_client_fields.port
  api_key        = var.sabnzbd_download_client_fields.api_key
  use_ssl        = var.sabnzbd_download_client_fields.use_ssl
  movie_category = "movies"
}

resource "radarr_download_client_qbittorrent" "qbittorrent" {
  enable         = var.qbittorrent_download_client_fields.enable
  priority       = var.qbittorrent_download_client_fields.priority
  name           = var.qbittorrent_download_client_fields.name
  host           = var.qbittorrent_download_client_fields.host
  port           = var.qbittorrent_download_client_fields.port
  use_ssl        = var.qbittorrent_download_client_fields.use_ssl
  movie_category = "movies"
}
