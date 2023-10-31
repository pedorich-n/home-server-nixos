{ writeShellScriptBin, nix }:
writeShellScriptBin "nix-modrinth-prefetch" ''
  url=$1
  path=$(${nix}/bin/nix-prefetch-url --print-path "$url" | tail -1)
  hash=$(nix-hash --type sha512 --flat "$path")

  echo "fetchurl { url = \"$url\"; sha512 = \"$hash\"; }"
''
