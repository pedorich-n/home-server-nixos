variable "base_url" {
  type = string
}

variable "prowlarr_api_key" {
  type      = string
  sensitive = true
}

variable "radarr_api_key" {
  type      = string
  sensitive = true
}

variable "sonarr_api_key" {
  type      = string
  sensitive = true
}

variable "indexer_credentials" {
  type      = map(any)
  sensitive = true
}

