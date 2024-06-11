{ pkgs, ... }:
let
  minecraftVersion = "1.20.1";
  forgeVersion = "47.3.1";
  version = "${minecraftVersion}-${forgeVersion}";
in
pkgs.runCommandNoCC "forge-${version}"
{
  inherit version;
  nativeBuildInputs = with pkgs; [
    cacert
    curl
    jre_headless
  ];

  outputHashMode = "recursive";
  outputHash = "sha256-DRzLUVL56wnl2SBemSmXCYtHysI42yYB8WF7GEFnMjA=";
}
  ''
    mkdir -p "$out"

    curl https://maven.minecraftforge.net/net/minecraftforge/forge/${version}/forge-${version}-installer.jar -o ./installer.jar
    java -jar ./installer.jar --installServer "$out"
  ''
