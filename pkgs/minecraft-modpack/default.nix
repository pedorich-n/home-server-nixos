{ pkgs, ... }:
let
  version = "V1.1.0";
in
pkgs.fetchPackwizModpack {
  pname = "money-guys-exploration";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/moneyguys-explorationrevival/-/raw/${version}/pack.toml";
  packHash = "sha256-RD8iPiT+B/NwA/21g+53WOWroU8y4CY6smcuq6GsOMU=";
}
