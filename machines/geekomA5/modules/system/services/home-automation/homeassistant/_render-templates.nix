{ networkingLib, pkgs, ... }:
let
  jsonFormat = pkgs.formats.json { };

  variables = {
    auth_url = networkingLib.mkUrl "authelia";
    url = networkingLib.mkUrl "homeassistant";
  };

in
pkgs.stdenv.mkDerivation {
  name = "homeassistant-blueprints";

  nativeBuildInputs = [ pkgs.makejinja ];

  dontConfigure = true;
  dontPatch = true;
  dontFixup = true;

  src = ./templates;

  env = {
    variablesPath = jsonFormat.generate "variables.json" variables;
  };

  buildPhase = ''
    runHook preBuild

    mkdir result

    makejinja --input "$src" \
              --output ./result \
              --data "$variablesPath" \
              --jinja-suffix ".j2" \
              --undefined "strict"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    mv result/sources/* $out/  

    runHook postInstall
  '';
}
