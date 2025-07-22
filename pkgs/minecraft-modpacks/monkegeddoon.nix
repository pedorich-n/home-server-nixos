{ pkgs, ... }:
let
  version = "0.8.0";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${version}/pack.toml";
  packHash = "sha256-aiemnXfebrnzIJXXMEuK3CfozUzE1XPomsjUnyLoUGI=";
}
