{ pkgs, ... }:
let
  ref = "797dbaee91ec2874274f1271d52959ad5cd37fe1";
  version = "0.0.10";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-hFnUqUuEUVxF1RtbNiRLiErjEWMGQMcV8WrIBYVpQOQ=";
}
