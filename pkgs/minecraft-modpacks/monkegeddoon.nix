{ pkgs, ... }:
let
  ref = "e7ca9aea96b9432bcc8c12106c4abd5a6d65ce68";
  version = "0.0.1-alpha";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-5z8WEojGG2TF3HQ7ErHO5TxfNhIChpmhFV4/yRhNZ+c=";
}
