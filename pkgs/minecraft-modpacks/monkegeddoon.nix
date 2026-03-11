{ pkgs, ... }:
let
  ref = "762779112be175f1bd01d6e23d062514c7b7c1eb";
  version = "0.0.11";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-M4XmYMWtqATJXBFIPxW7ulyAcuzzy0eGwpdtWM1YIwE=";
}
