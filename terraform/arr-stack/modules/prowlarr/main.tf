resource "prowlarr_sync_profile" "interactive" {
  name                      = "Interactive"
  enable_rss                = false
  enable_automatic_search   = false
  enable_interactive_search = true
  minimum_seeders           = 20
}

resource "prowlarr_sync_profile" "automatic" {
  name                      = "Automatic"
  enable_rss                = false
  enable_automatic_search   = true
  enable_interactive_search = true
  minimum_seeders           = 20
}
