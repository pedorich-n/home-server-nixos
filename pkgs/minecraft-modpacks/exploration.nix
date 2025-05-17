{ pkgs, ... }:
let
  version = "V2.0.0F";
in
pkgs.fetchPackwizModpack {
  pname = "money-guys-exploration";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/moneyguys-explorationrevival/-/raw/${version}/pack.toml";
  packHash = "sha256-IwTgVvTHHOZHNfF94rec/rCcOataXuo2lKlohrRlW2E=";
}
