{ pkgs, ... }:
let
  version = "RC-1.0.3";
in
pkgs.fetchPackwizModpack {
  pname = "crying-obsidian";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/crying-obsidian/-/raw/${version}/pack.toml";
  packHash = "sha256-qikNdAAIMhdcJHYyzhEv6jaoLY7NaAPehVUVUO9RntE=";
}
