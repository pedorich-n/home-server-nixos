{ lib, ... }:
{
  programs.keychain.enable = lib.mkOverride 950 false;
}
