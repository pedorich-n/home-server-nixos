{ lib, pkgs, ... }:
{
  users = {
    mutableUsers = lib.mkDefault false;
    users = {
      #NOTE - Need to set the initial password, because in case of a new machine it will have a new identity key, 
      # and agenix secrets aren't encrypted with it yet

      root = {
        initialPassword = lib.mkDefault "nixos";
        shell = pkgs.zsh;
      };
    };
  };
}
