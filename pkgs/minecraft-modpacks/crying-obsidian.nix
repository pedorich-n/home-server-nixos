{ pkgs, ... }:
let
  version = "aa29421eaae644195f7dbc8cc0b4b0a2b89f8e50";
in
pkgs.fetchPackwizModpack {
  pname = "crying-obsidian";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/crying-obsidian/-/raw/${version}/pack.toml";
  packHash = "sha256-nueZCJ7z/jbTarL8Je5Xp2q4OZM6TS+H4o7MmKGCGzs=";
}
