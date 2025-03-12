{ self, inputs, ... }: {
  _module.args.flake = self;
  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
      overlays = [
        inputs.nix-minecraft.overlays.default
      ];
    };
  };
}
