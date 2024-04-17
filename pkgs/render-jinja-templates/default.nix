{ lib, pkgs }:
{ name, vars, templates }:
pkgs.stdenvNoCC.mkDerivation {
  inherit name;

  passAsFile = [ "varsData" ];
  varsData = builtins.toJSON vars;

  phases = [ "unpackPhase" "buildPhase" ];

  src = templates;
  # https://discourse.nixos.org/t/mkderivation-src-as-list-of-filenames/3537/5
  unpackPhase = ''
    mkdir templates

    for srcFile in $src/*; do
      # Copy file into build dir
      local tgt=templates/$(basename $srcFile)
      cp $srcFile $tgt
    done
  '';

  nativeBuildInputs = with pkgs; [ jinja2-cli coreutils ];

  buildPhase = ''
    mkdir $out

    for template in ./templates/*; do
      ${lib.getExe pkgs.jinja2-cli} --format=json "''${template}" "''${varsDataPath}" --outfile $out/$(basename ''${template})
    done
  '';
}
