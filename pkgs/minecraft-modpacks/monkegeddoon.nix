{ pkgs, ... }:
let
  ref = "fix-hashes";
  version = "0.0.1-alpha";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  # url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${commitHash}/pack.toml";
  url = "https://gitlab.com/pedorich-n/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-ewIQYYvLRJrMh4KGEWaK1yPuQfDE8qu1u9TfQ1G93kw=";
}
