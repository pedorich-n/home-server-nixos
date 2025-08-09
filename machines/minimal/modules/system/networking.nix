{ lib, ... }:
{
  networking.hostName = lib.mkForce "nixos";
}
