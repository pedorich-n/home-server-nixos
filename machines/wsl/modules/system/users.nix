{ config, pkgs, lib, ... }: {
  users.users = {
    root = {
      password = lib.mkForce null;
      hashedPasswordFile = config.age.secrets.os_root_password.path;
    };

    #FIXME: different username? It's the same in server nixos, but the configurations should be different
    user = {
      uid = 1000;
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.os_user_password.path;
      shell = pkgs.zsh;
      extraGroups = [
        "podman"
        "wheel"
        "systemd-journal"
      ];
    };
  };

  #LINK - shared-modules/nixos/common/options/system/users/home-manager.nix
  custom.users.homeManagerUsers = [ "root" "user" ];
}
