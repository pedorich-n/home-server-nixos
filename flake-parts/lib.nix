{ withSystem, flake, inputs, lib, ... }:
{
  imports = [
    ./_modules/lib.nix
  ];

  flake = {
    lib = inputs.haumea.lib.load {
      src = ../lib;
      inputs = {
        inherit inputs lib withSystem flake;
        inherit (inputs) haumea;
      };
    };
  };
}
