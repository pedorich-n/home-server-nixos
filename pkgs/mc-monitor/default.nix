{ pkgs, ... }:
let
  sources = pkgs.callPackage ./_sources/generated.nix { };
in
pkgs.buildGoModule rec {
  inherit (sources.mc-monitor) pname version src vendorHash;

  ldflags = [ "-s" "-w" ];

  meta = {
    homepage = "https://github.com/itzg/mc-monitor";
    mainProgram = pname;
  };
}
