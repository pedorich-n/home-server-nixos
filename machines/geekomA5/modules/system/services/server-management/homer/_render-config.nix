{ config, lib, pkgs }:
pkgs.stdenvNoCC.mkDerivation {
  name = "homer-config-rendered.yml";

  src = ./config.yml;
  unpackCmd = ''
    mkdir src
    cp $src src/$(stripHash $src)
  '';

  passAsFile = [ "varsData" ];
  varsData = builtins.toJSON {
    inherit (config.custom.networking) domain;
  };

  nativeBuildInputs = with pkgs; [ jinja2-cli ];

  buildPhase = ''
    ${lib.getExe pkgs.jinja2-cli} --format=json config.yml "''${varsDataPath}" --outfile $out
  '';
}