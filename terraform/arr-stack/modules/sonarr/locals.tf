locals {
  naming_trash = jsondecode(data.terracurl_request.naming.response)
}
