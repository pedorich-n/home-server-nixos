{ pkgs, ... }:
let
  ref = "c3f2199640bafa21bc3ff584a9f47d72e33542a1";
  version = "0.0.8";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-HEuQ09CZHhbwWS3fmwH/X7XMUANxqMVOpXQHkQfw7AE=";
}
