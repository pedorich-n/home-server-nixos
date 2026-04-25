{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = lib.filesystem.packagesFromDirectoryRecursive {
        inherit (pkgs) callPackage;
        directory = ../pkgs;
      };
    };
}
