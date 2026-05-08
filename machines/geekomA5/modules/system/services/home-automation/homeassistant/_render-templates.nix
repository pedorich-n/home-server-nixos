{
  networkingLib,
  trustedProxies,
  stdenv,
  makejinja,
  writers,
  ...
}:
let
  variables = {
    auth_url = networkingLib.mkUrl "authelia";
    url = networkingLib.mkUrl "homeassistant";
    inherit trustedProxies;
  };

in
stdenv.mkDerivation {
  name = "homeassistant-blueprints";

  nativeBuildInputs = [ makejinja ];

  dontConfigure = true;
  dontPatch = true;
  dontFixup = true;

  src = ./templates;

  env = {
    variablesPath = writers.writeJSON "variables.json" variables;
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
