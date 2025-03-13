{ pkgs, ... }:
let
  version = "V1.1.1";
in
pkgs.fetchPackwizModpack {
  pname = "money-guys-exploration";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/moneyguys-explorationrevival/-/raw/${version}/pack.toml";
  packHash = "sha256-qIRjoKE8F3zNrRjx90dN95qqXSfC9m1Y2dYFCtFhwno=";
}
