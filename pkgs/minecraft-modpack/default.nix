{ pkgs, ... }:
let
  version = "V1.1.2";
in
pkgs.fetchPackwizModpack {
  pname = "money-guys-exploration";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/moneyguys-explorationrevival/-/raw/${version}/pack.toml";
  packHash = "sha256-FzDbtGXpNYAnFpsB5aF3D6NXdYvBVmhydMbMhd1ZgSk=";
}
