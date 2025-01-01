{ config, lib, ... }: {
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
        extraGroups = [ "zigbee" "render" ];
        password = lib.mkForce null;
        hashedPasswordFile = config.age.secrets.os_user_password.path;
      };
    };
  };

  #LINK - shared-modules/nixos/custom/system/home-manager.nix
  custom.users.homeManagerUsers = [ "root" "user" ];
}
