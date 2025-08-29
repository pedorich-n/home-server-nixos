resource "terracurl_request" "sabnzbd_categories" {
  for_each = local.categories

  name           = "createCategory_${each.key}"
  method         = "POST"
  url            = var.base_url
  response_codes = local.default_response_codes
  request_parameters = merge(local.default_request_parameters, {
    mode    = "set_config"
    section = "categories"
    name    = each.key
    dir     = each.key
  })

  destroy_skip = true

  #   destroy_request_parameters = merge(local.default_request_parameters, {
  #     mode    = "del_config"
  #     section = "categories"
  #     keyword = each.key
  #   })
}

resource "terracurl_request" "sabnzbd_servers" {
  for_each = local.servers

  name           = "createServer_${each.key}"
  method         = "POST"
  url            = var.base_url
  response_codes = local.default_response_codes
  request_parameters = merge(local.default_request_parameters, {
    mode        = "set_config"
    section     = "servers"
    name        = each.key
    host        = each.value.base_url
    port        = 563
    ssl         = 1
    connections = each.value.connections
    priority    = each.value.priority
    quota       = each.value.quota

    username = var.sabnzbd_servers[each.key].username
    password = var.sabnzbd_servers[each.key].password
  })

  destroy_skip = true

  #   destroy_request_parameters = merge(local.default_request_parameters, {
  #     mode    = "del_config"
  #     section = "servers"
  #     keyword = each.key
  #   })
}
