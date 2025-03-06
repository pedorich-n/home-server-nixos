{ pkgs, ... }:
let
  version = "Release-Candidate-v1.0.1";
in
pkgs.fetchPackwizModpack {
  pname = "money-guys-exploration";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/moneyguys-explorationrevival/-/raw/${version}/pack.toml";
  packHash = "sha256-ubR0EXyJq/gbJfCbxYQ7aQHal5uR4Ldbp2oSOEOatrw=";
}
