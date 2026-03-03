{ pkgs, ... }:
let
  ref = "182993520cf22b7891dd249f892d34d959e08391";
  version = "0.0.4-alpha";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-jeeiNS4XJ3P7LocXi3NuA2gqGOa3DqM7RYCAARcDGV8=";
}
