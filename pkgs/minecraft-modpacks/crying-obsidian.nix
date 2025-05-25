{ pkgs, ... }:
let
  version = "V1.1.1";
in
pkgs.fetchPackwizModpack {
  pname = "crying-obsidian";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/crying-obsidian/-/raw/${version}/pack.toml";
  packHash = "sha256-ZI36rw4bsjrOq79Cnl9LaHBY5KYdojjHu0UVOgagVWs=";
}
