{
  flake,
  ...
}:
{
  perSystem =
    {
      config,
      pkgs,
      deployPkgs,
      lib,
      ...
    }:
    let
      tools = lib.filesystem.packagesFromDirectoryRecursive {
        callPackage = lib.callPackageWith (
          pkgs
          // {
            inherit flake;
            inherit (deployPkgs.deploy-rs) deploy-rs;
            inherit (config) packages;
          }
        );
        directory = ../pkgs/tools;
      };

      mkApp =
        pkg:
        {
          type = "app";
          program = pkg;
        }
        // (lib.optionalAttrs (pkg ? meta.description) { meta.description = pkg.meta.description; });

      apps = lib.mapAttrs (_name: pkg: mkApp pkg) tools;
    in
    {
      inherit apps;
    };
}
