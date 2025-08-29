variable "base_url" {
  type = string
}

variable "api_key" {
  type      = string
  sensitive = true
}

variable "sabnzbd_servers" {
  type      = map(any)
  sensitive = true
}
