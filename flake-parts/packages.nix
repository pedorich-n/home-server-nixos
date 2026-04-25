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
      sources = pkgs.callPackage ../pkgs/_sources/generated.nix { };

      loadPackages =
        dir:
        flake.lib.tools.flattenDerivationsTree (
          lib.filesystem.packagesFromDirectoryRecursive {
            callPackage = lib.callPackageWith (pkgs // { inherit sources; });
            directory = dir;
          }
        );
    in
    {
      packages = loadPackages ../pkgs/nixos;
    };
}
