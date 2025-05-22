{ pkgs, ... }:
let
  version = "RC-1.1.2";
in
pkgs.fetchPackwizModpack {
  pname = "crying-obsidian";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/crying-obsidian/-/raw/${version}/pack.toml";
  # url = "https://gitlab.com/pedorich-n/crying-obsidian/-/raw/${version}/pack.toml";
  packHash = "sha256-Spg+ObSmEp6sfTLcq/oA1GTryQ+k5j6neI+AQvO92Xs=";
}
