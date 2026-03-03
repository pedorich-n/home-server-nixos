{ pkgs, ... }:
let
  ref = "77e42e2f6cd76ff27d010d9d013b2fef91b45771";
  version = "0.0.6-alpha";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-3fRzDIgGRKGyli0II+v0n/fTOLKSfKSS9A+TZDHCEC8=";
}
