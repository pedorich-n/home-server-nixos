variable "base_url" {
  type = string
}

variable "sonarr_api_key" {
  type      = string
  sensitive = true
}

variable "sabnzbd_download_client_fields" {
  type = object({
    enable   = bool
    priority = number
    name     = string
    host     = string
    port     = number
    api_key  = string
    use_ssl  = bool
  })
}

variable "qbittorrent_download_client_fields" {
  type = object({
    enable   = bool
    priority = number
    name     = string
    host     = string
    port     = number
    use_ssl  = bool
  })
}
