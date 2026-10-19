resource "prowlarr_tag" "trawl" {
  label = "trawl"
}

resource "prowlarr_indexer_proxy_http" "trawl" {
  name = "Trawl"
  host = "127.0.0.1"
  # LINK - machines/geekomA5/modules/system/services/data-library/containers.nix:53
  port = 33011

  username = ""
  password = ""

  tags = [prowlarr_tag.trawl.id]
}
