{ pkgs, ... }:
let
  version = "RC-1.0.2";
in
pkgs.fetchPackwizModpack {
  pname = "crying-obsidian";
  inherit version;
  url = "https://gitlab.com/pedorich-n/crying-obsidian/-/raw/${version}/pack.toml";
  packHash = "sha256-DEYCsfYDgJ1SaVaQO0YrwzKr7/Z0S6977jRGv19/KzE=";
}
