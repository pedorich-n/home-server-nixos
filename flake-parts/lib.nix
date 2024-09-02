_:
{ inputs, lib, ... }:
{
  flake = {
    lib = inputs.haumea.lib.load {
      src = ../lib;
      inputs = {
        inherit (inputs) haumea;
        inherit lib;
      };
    };
  };
}
