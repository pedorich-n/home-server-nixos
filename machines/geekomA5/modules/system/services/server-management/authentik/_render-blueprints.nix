{ config, lib, pkgs }:
pkgs.stdenvNoCC.mkDerivation {
  name = "authentik-blueprints";

  src = ./blueprints;

  passAsFile = [ "varsData" ];
  varsData = builtins.toJSON {
    inherit (config.custom.networking) domain;
  };

  nativeBuildInputs = with pkgs; [ jinja2-cli coreutils ];

  buildPhase = ''
    mkdir $out

    for template in ./*.yaml; do
      ${lib.getExe pkgs.jinja2-cli} --format=json "''${template}" "''${varsDataPath}" --outfile $out/$(basename ''${template})
    done
  '';
}
