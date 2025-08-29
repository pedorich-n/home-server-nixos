variable "server_domain" {
  type = string
}

variable "base_url" {
  type = string
}

variable "api_key" {
  type      = string
  sensitive = true
}

variable "sabnzbd_servers" {
  type = map(object({
    username = string
    password = string
  }))
  sensitive = true
}
