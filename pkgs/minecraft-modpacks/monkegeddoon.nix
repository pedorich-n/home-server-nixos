{ pkgs, ... }:
let
  ref = "74336fd37a99d02b6256e169a744a339f06aef6b";
  version = "0.0.9";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-t2Dlfvh057xhiPzR7HxF29aJpKBIYWze49kc9h+iRWQ=";
}
