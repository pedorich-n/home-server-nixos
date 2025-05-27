{ pkgs, ... }:
let
  version = "V1.3.2";
in
pkgs.fetchPackwizModpack {
  pname = "crying-obsidian";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/crying-obsidian/-/raw/${version}/pack.toml";
  packHash = "sha256-cpPMBy/NuN6AjkuxVns08YwY8AgRvcEv2jWKiVvrs1A=";
}
