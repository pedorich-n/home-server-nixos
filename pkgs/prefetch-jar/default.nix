{ pkgs, ... }:
# TODO: use (${lib.getExe' pkgs.nix "nix-prefetch-url"}, ${lib.getExe' pkgs.nix "nix-hash"} once in stable
pkgs.writeShellScriptBin "nix-prefetch-jar" ''
  url=$1
  path=$(${pkgs.nix}/bin/nix-prefetch-url --print-path "$url" | tail -1)
  hash=$(${pkgs.nix}/bin/nix-hash --type sha512 --flat "$path")

  echo "fetchurl { url = \"$url\"; sha512 = \"$hash\"; }"
''
