{ pkgs, ... }:
let
  ref = "2826f62946ceca3b336f05bf6e7447e845e46469";
  version = "0.0.3-alpha";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-Qe7KbVLIgWnM6qcCYmzIMCqHthDZUXT3YRcrf74DirU=";
}
