{ pkgs, ... }:
let
  version = "0.7.2";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${version}/pack.toml";
  packHash = "sha256-0/f3rFWKxHIVhajtbiVpEMyTkl+vpHoxY+LcoZwzEOk=";
}
