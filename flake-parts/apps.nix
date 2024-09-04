{ flake, ... }: {
  perSystem = { pkgs, deployPkgs, lib, ... }: {
    apps = {
      generate-host-key.program = pkgs.callPackage ../pkgs/generate-host-key { };

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
