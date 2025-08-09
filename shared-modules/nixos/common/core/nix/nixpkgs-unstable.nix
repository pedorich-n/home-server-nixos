{ lib, ... }:
{
  custom.nixpkgs-unstable.enable = lib.mkDefault true;
}
