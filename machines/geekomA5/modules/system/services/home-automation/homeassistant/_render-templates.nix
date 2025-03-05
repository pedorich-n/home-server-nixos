{ pkgs, ... }:
pkgs.stdenv.mkDerivation {
  name = "authentik-blueprints";

  nativeBuildInputs = [ pkgs.makejinja ];

  dontConfigure = true;
  dontPatch = true;
  dontFixup = true;

  src = ./templates;

  buildPhase = ''
    runHook preBuild

    mkdir result

    makejinja --input "$src" \
              --output ./result \
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
