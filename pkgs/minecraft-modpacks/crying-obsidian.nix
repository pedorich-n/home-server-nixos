{ pkgs, ... }:
let
  version = "V1.3.5";
in
pkgs.fetchPackwizModpack {
  pname = "crying-obsidian";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/crying-obsidian/-/raw/${version}/pack.toml";
  packHash = "sha256-kp/XvuoXwEa96/8wdLoe3SrrZzNuUPbBnHBSUMw5Nl4=";
}
