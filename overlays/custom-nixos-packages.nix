_: prev:
let
  sources = prev.callPackage ../pkgs/_sources/generated.nix { };
in
prev.lib.filesystem.packagesFromDirectoryRecursive {
  callPackage = prev.lib.callPackageWith (prev // { inherit sources; });
  directory = ../pkgs/nixos;
}
