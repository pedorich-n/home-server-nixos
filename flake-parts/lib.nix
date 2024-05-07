_:
{ inputs, lib, ... }:
{
  flake = {
    lib = inputs.haumea.lib.load {
      src = ../lib/global;
      inputs = {
        inherit (inputs) haumea;
        inherit lib;
      };
    };
  };
}
