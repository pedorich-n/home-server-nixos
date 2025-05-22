{ pkgs, ... }:
let
  version = "V1.0.0";
in
pkgs.fetchPackwizModpack {
  pname = "crying-obsidian";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/crying-obsidian/-/raw/${version}/pack.toml";
  packHash = "sha256-XPoNZCayw/ZBwI+LvRKQzgEBC33kk97bWj0TWyk77w8=";
}
