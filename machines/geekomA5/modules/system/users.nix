{
  config,
  lib,
  pkgs,
  ...
}:
{
  users = {
    groups = {
      zigbee = {
        gid = 992; # Was set by the activation script before I needed to know it in build-time
      };

      media = {
        gid = 950;
      };

      fuse = { };

      mail = { };
    };

    users = {
      root = {
        password = lib.mkForce null;
        hashedPasswordFile = config.sops.secrets."os_passwords/root".path;
      };

      user = {
        uid = 1000;
        isNormalUser = true;
        shell = pkgs.zsh;
        hashedPasswordFile = config.sops.secrets."os_passwords/user".path;
        openssh.authorizedKeys.keys = config.custom.ssh.keys;
        extraGroups = [
          "media"
          "podman"
          "render"
          "systemd-journal"
          "wheel"
          "zigbee"
        ];
      };
    };
  };

  #LINK - shared-modules/nixos/presets/home-manager/options/system/users/home-manager.nix
  custom.users.homeManagerUsers = [
    "root"
    "user"
  ];
}
