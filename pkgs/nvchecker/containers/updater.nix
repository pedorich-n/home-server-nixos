{ pkgs, ... }:
let
  config = pkgs.callPackage ./config.nix { };
in
pkgs.writeShellApplication {
  name = "update-containers";
  runtimeInputs = [
    pkgs.gitMinimal
    pkgs.nvchecker
  ];

  passthru = {
    inherit config;
  };

  text = ''
    ROOT="$(git rev-parse --show-toplevel)"
    TARGET="''${ROOT}/containers"
    export TARGET

    nvchecker --file ${config}
  '';
}
