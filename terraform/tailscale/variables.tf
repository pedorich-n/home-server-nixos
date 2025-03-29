variable "server_hostname" {
  type = string
}

variable "server_domain" {
  type = string
}

variable "s3_backend_application_key_id" {
  type      = string
  sensitive = true
}

variable "s3_backend_application_key" {
  type      = string
  sensitive = true
}

variable "s3_backend_bucket" {
  type      = string
  sensitive = true
}
