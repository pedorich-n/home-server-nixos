{ pkgs, ... }:
let
  ref = "041be8c4256824f826cf6af0fdbb92ffabb56a65";
  version = "0.0.7-alpha";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-ylWy9xmO7DfB+gLXHUx9VkeXayrSYrANfCoXFkbEt0g=";
}
