{
  flake,
  ...
}:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      loadPackages =
        dir:
        flake.lib.tools.flattenDerivationsTree (
          lib.filesystem.packagesFromDirectoryRecursive {
            inherit (pkgs) callPackage;
            directory = dir;
          }
        );
    in
    {
      packages = (loadPackages ../pkgs/nixos) // (loadPackages ../pkgs/tools);
    };
}
