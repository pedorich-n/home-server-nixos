{ config, lib, pkgs, ... }:
let
  shell = pkgs.zsh;
in
{
  users = {
    mutableUsers = lib.mkDefault false;
    users = {
      #NOTE - Need to set the initial password, because in case of a new machine it will have a new identity key, 
      # and agenix secrets aren't encrypted with it yet

      root = {
        initialPassword = lib.mkDefault "nixos";
        inherit shell;
      };

      user = {
        inherit shell;
        uid = lib.mkDefault 1000;
        isNormalUser = true;
        initialPassword = lib.mkDefault "nixos";
        extraGroups = [
          "wheel"
          "systemd-journal"
        ]
        ++ lib.optional config.virtualisation.docker.enable "docker"
        ++ lib.optional config.virtualisation.podman.enable "podman";
      };
    };
  };
}
