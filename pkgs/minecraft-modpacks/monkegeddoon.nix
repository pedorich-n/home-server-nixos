{ pkgs, ... }:
let
  ref = "95354a59241a3eebaefc895e5021cc52154f8dae";
  version = "0.0.1-alpha";
in
pkgs.fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-ieUrkpQMUisIBlG7j0+0ltP3PTWe7aRKAUVM8rF4jJk=";
}
