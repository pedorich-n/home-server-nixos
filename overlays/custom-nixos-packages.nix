_: prev:
prev.lib.filesystem.packagesFromDirectoryRecursive {
  inherit (prev) callPackage;
  directory = ../pkgs/nixos;
}
