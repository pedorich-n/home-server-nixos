{
  flake,
  ...
}:
{
  perSystem =
    {
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
    in
    {
      apps = {
        generate-host-keys = mkApp tools.nixos-bootstrap.generate-host-keys;
        convert-host-keys = mkApp tools.nixos-bootstrap.convert-host-keys;
        update-nvfetcher = mkApp tools.update-nvfetcher;
        deploy = mkApp tools.deploy-nixos;
        build-iso = mkApp tools.build-iso;
      };
    };
}
