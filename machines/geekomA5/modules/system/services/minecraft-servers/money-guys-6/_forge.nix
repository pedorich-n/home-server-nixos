{ pkgs, ... }:
let
  minecraftVersion = "1.20.1";
  forgeVersion = "47.3.33";
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
  outputHash = "sha256-aOugxrl+mahBLQUGezL14o+pogxgx4M+FdoQH4+74K0=";
}
  ''
    mkdir -p "$out"

    curl https://maven.minecraftforge.net/net/minecraftforge/forge/${version}/forge-${version}-installer.jar -o ./installer.jar
    java -jar ./installer.jar --installServer "$out"
  ''
