{ pkgs, ... }:
let
  version = "v1.3.0";
in
pkgs.fetchPackwizModpack {
  pname = "money-guys-exploration";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/moneyguys-explorationrevival/-/raw/${version}/pack.toml";
  packHash = "sha256-UGv2uSl/x7BfO7FGzdEJDFCwPMUCTT/Sz2xbPStTuPE=";
}
