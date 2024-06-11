{ pkgs, forge, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "minecraft-server";
  version = "forge-${forge.version}";
  meta.mainProgram = "server";

  dontUnpack = true;
  dontConfigure = true;

  # TODO: don't place the file in /bin
  buildPhase = ''
    mkdir -p $out/bin

    cp "${forge}/libraries/net/minecraftforge/forge/${forge.version}/unix_args.txt" "$out/bin/unix_args.txt"
  '';

  installPhase = ''
    cat <<\EOF >>$out/bin/server
    ${pkgs.jre_headless}/bin/java "$@" "@${builtins.placeholder "out"}/bin/unix_args.txt" nogui
    EOF

    chmod +x $out/bin/server
  '';

  fixupPhase = ''
    substituteInPlace $out/bin/unix_args.txt \
      --replace-fail "libraries" "${forge}/libraries"
  '';
}
