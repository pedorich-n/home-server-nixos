{
  networkingLib,
  autheliaLib,
  stdenv,
  makejinja,
  writers,
  ...
}:
let
  variables = {
    url = networkingLib.mkLocalUrl "homeassistant";
    oidc_discovery_url = autheliaLib.discoveryUrl;
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
