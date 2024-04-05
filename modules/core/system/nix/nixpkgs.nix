{ inputs, system, lib, ... }:
let
  settings = {
    config = {
      allowUnfree = true;
    };
  };
in
{
  _module.args.pkgs-unstable = lib.mkDefault (import inputs.nixpkgs-unstable ({ inherit system; } // settings));

  nixpkgs = lib.mkDefault settings;
}
