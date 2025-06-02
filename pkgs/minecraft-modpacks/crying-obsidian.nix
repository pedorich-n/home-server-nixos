{ pkgs, ... }:
let
  version = "V1.3.4";
in
pkgs.fetchPackwizModpack {
  pname = "crying-obsidian";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/crying-obsidian/-/raw/${version}/pack.toml";
  packHash = "sha256-UOZcMe4sYjgm5+DtmDqZFzGgp1Sp1SKJadhXZtLl864=";
}
