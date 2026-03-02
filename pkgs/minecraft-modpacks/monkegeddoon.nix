{ pkgs, ... }:
let
  ref = "05cc6eba35bb6420096d732e163ca4d1de1e9ed5";
  version = "0.0.2-alpha";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-CcP7ndGngxjKd9Bm9o9XyHaLRRHBLE57dXL0k3XH7ZM=";
}
