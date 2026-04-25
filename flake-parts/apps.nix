{ flake, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      deployPkgs,
      lib,
      ...
    }:
    {
      apps = {
        generate-host-keys.program = config.packages."nixos-bootstrap.generate-host-keys";
        convert-host-keys.program = config.packages."nixos-bootstrap.convert-host-keys";

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
