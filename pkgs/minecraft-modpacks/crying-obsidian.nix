{ pkgs, ... }:
let
  version = "V1.0.3";
in
pkgs.fetchPackwizModpack {
  pname = "crying-obsidian";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/crying-obsidian/-/raw/${version}/pack.toml";
  packHash = "sha256-BEaWsD9saCNnmG6HqdCMScSv/O2chfsVgCpJpaU/K4Y=";
}
