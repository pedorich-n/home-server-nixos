{ pkgs, ... }:
let
  ref = "1de7b61523c85bde49ed3bc2876163ce1ddbb085";
  version = "0.0.1-alpha";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-mathFlPpBRBiF9NWUflkaWUAz2LuQVSCYWzJdMl2j8w=";
}
