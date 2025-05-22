{ pkgs, ... }:
let
  version = "e19acf3";
in
pkgs.fetchPackwizModpack {
  pname = "crying-obsidian";
  inherit version;
  # url = "https://gitlab.com/pablo_peraza/crying-obsidian/-/raw/${version}/pack.toml";
  url = "https://gitlab.com/pedorich-n/crying-obsidian/-/raw/${version}/pack.toml";
  packHash = "sha256-a1D3waVXD7B5iKB3wApEBxcI3q1SLiq6jL9QYkAO+kw=";
}
