{ config, lib, pkgs, ... }: {
  users = {
    groups = {
      zigbee = { };
    };

    users = {
      root = {
        password = lib.mkForce null;
        hashedPasswordFile = config.age.secrets.os_root_password.path;
      };

      user = {
        uid = 1000;
        isNormalUser = true;
        shell = pkgs.zsh;
        hashedPasswordFile = config.age.secrets.os_user_password.path;
        openssh.authorizedKeys.keys = config.custom.ssh.keys;
        extraGroups = [
          "zigbee"
          "render"
          "wheel"
          "systemd-journal"
          "podman"
        ];
      };
    };
  };

  #LINK - shared-modules/nixos/common/options/system/users/home-manager.nix
  custom.users.homeManagerUsers = [ "root" "user" ];
}
