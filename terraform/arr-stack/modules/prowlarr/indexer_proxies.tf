resource "prowlarr_tag" "trawl" {
  label = "trawl"
}

resource "prowlarr_indexer_proxy_http" "trawl" {
  name = "Trawl"
  host = "127.0.0.1"
  # LINK - machines/geekomA5/modules/system/services/trawl/containers.nix:18
  port = 33201

  username = ""
  password = ""

  tags = [prowlarr_tag.trawl.id]
}
