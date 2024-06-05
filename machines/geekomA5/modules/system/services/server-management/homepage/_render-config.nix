{ config, lib, pkgs }:
pkgs.stdenvNoCC.mkDerivation {
  name = "homepage-config-rendered";

  src = ./config;

  passAsFile = [ "varsData" ];
  varsData = builtins.toJSON {
    inherit (config.custom.networking) domain;
    logo_base = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png";
  };

  nativeBuildInputs = with pkgs; [ jinja2-cli coreutils ];

  buildPhase = ''
    mkdir $out

    for template in ./*; do
      ${lib.getExe pkgs.jinja2-cli} --format=json "''${template}" "''${varsDataPath}" --outfile $out/$(basename ''${template})
    done
  '';

}
