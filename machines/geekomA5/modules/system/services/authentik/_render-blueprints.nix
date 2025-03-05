{ domain, pkgs, ... }:
let
  jsonFormat = pkgs.formats.json { };

  variables = {
    server_domain = domain;
    icons_base_url = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png";

    # This one is used to group application in Authentik Dashboard
    applicationGroups = {
      serverManagement = "Server Management";
      homeAutomation = "Home Automation";
      services = "Services";
      media = "Media";
      mediaManagement = "Media Management";
    };

    # This one is for access management to applications
    accessGroups = {
      serverAdmins = "Server Admins";
      media = "Media";
      mediaAdmins = "Media Admins";
    };
  };
in
pkgs.stdenv.mkDerivation {
  name = "authentik-blueprints";

  nativeBuildInputs = [ pkgs.makejinja ];

  dontConfigure = true;
  dontPatch = true;
  dontFixup = true;

  src = ./blueprints;

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
