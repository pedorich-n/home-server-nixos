{ config, lib, ... }:
let
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8hr31myOgDIgehpr5QlnPQMXNj+PmQ2EC/YvjymHiP pedorich.n@gmail.com";
in
{
  users = {
    groups = {
      docker = { };
      podman = { };
    };

    mutableUsers = lib.mkDefault false;
    users = {
      # Need to set the inital password, because in case of a new machine it will have a new identity key, 
      # and agenix secrets aren't encrypted with it yet

      root = {
        hashedPasswordFile = config.age.secrets.root_password_hashed.path;
        openssh.authorizedKeys.keys = [
          sshKey
        ];
      };

      user = {
        uid = lib.mkDefault 1000;
        isNormalUser = true;
        useDefaultShell = true;
        hashedPasswordFile = config.age.secrets.user_password_hashed.path;
        extraGroups = [
          "docker"
          "podman"
          "wheel"
          "systemd-journal"
          "plugdev"
        ];
        openssh.authorizedKeys.keys = [
          sshKey
        ];
      };
    };
  };
}
