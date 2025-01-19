{ lib, pkgs, ... }:
{
  users = {
    mutableUsers = lib.mkDefault false;
    users = {
      #NOTE - Need to set the initial password, because in case of a new machine it will have a new identity key, 
      # and secrets can't yet be decrypted with it

      root = {
        initialPassword = lib.mkDefault "nixos";
        shell = pkgs.zsh;
      };
    };
  };
}
