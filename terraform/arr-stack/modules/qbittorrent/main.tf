resource "terracurl_request" "qbittorrent_preferences" {
  name           = "setPreferences"
  method         = "POST"
  url            = "${var.base_url}/app/setPreferences"
  response_codes = local.default_response_codes
  headers        = local.default_headers
  request_body   = "json=${jsonencode(local.preferences)}"

  skip_destroy = true
}

resource "terracurl_request" "qbittorrent_categories" {
  for_each = local.categories

  name           = "createCategory_${each.key}"
  method         = "POST"
  url            = "${var.base_url}/torrents/createCategory"
  response_codes = local.default_response_codes
  headers        = local.default_headers
  request_body   = "category=${each.key}&savePath=${each.key}"

  destroy_url            = "${var.base_url}/torrents/removeCategories"
  destroy_method         = "DELETE"
  destroy_headers        = local.default_headers
  destroy_response_codes = local.default_response_codes
}
