{ flake, ... }:
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
        inherit (pkgs) callPackage;
        directory = ../pkgs/tools;
      };
    in
    {
      apps = {
        generate-host-keys.program = tools.nixos-bootstrap.generate-host-keys;
        convert-host-keys.program = tools.nixos-bootstrap.convert-host-keys;
        update-nvfetcher.program = tools.update-nvfetcher;

        deploy.program = pkgs.writeShellScriptBin "deploy-nixos" ''
          system=$1
          shift 1

          ${lib.getExe deployPkgs.deploy-rs.deploy-rs} "${flake}#$system" "$@"
        '';

        build-iso.program = pkgs.writeShellScriptBin "build-iso" ''
          system=$1
          shift 1

          nix build "${flake}#nixosConfigurations.''${system}.config.system.build.isoImage" "$@"
        '';
      };
    };
}
