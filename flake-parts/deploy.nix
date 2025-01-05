{ inputs, ... }: {
  perSystem = { system, pkgs, /* deployPkgs, */ ... }: {
    _module.args = {
      # From https://github.com/serokell/deploy-rs/blob/88b3059b020da69cbe16526b8d639bd5e0b51c8b/README.md?plain=1#L89-L114
      deployPkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.deploy-rs.overlays.default
          (_: prev: {
            deploy-rs = {
              inherit (pkgs) deploy-rs;
              lib = prev.deploy-rs.lib;
            };
          })
        ];
      };
    };

    # checks = lib.mkIf (flake.deploy or { } != { }) (deployPkgs.deploy-rs.lib.deployChecks flake.deploy);
  };
}
