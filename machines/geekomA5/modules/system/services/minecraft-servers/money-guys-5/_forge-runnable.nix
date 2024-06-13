{ lib, pkgs, forge, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "minecraft-server";
  version = "forge-${forge.version}";
  meta.mainProgram = "server";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  buildInputs = [ forge ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    args=$(cat ${forge}/libraries/net/minecraftforge/forge/${forge.version}/unix_args.txt | tr '\n' ' ')
    echo "${lib.getExe' pkgs.jre_headless "java"} \"\$@\" ''${args} nogui" >>$out/bin/server
    chmod +x $out/bin/server

    runHook postInstall
  '';

  fixupPhase = ''
    substituteInPlace $out/bin/server \
      --replace-fail "libraries" "${forge}/libraries"
  '';
}
