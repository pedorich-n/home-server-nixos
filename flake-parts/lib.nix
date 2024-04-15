{ inputs, ... }: {
  flake = {
    lib = inputs.haumea.lib.load {
      src = ../lib/global;
      inputs = {
        inherit (inputs.nixpkgs) lib;
        inherit (inputs) haumea;
      };
    };
  };
}
