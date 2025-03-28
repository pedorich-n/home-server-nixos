variable "base_url" {
  type = string
}

variable "api_key" {
  type      = string
  sensitive = true
}

variable "indexer_credentials" {
  type      = map(any)
  sensitive = true
}
