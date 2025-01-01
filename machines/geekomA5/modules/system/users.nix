{ config, ... }: {
  users = {
    groups = {
      zigbee = { };
    };

    users = {
      root = {
        hashedPasswordFile = config.age.secrets.os_root_password.path;
      };
      user = {
        extraGroups = [ "zigbee" "render" ];
        hashedPasswordFile = config.age.secrets.os_user_password.path;
      };
    };
  };

  #LINK - shared-modules/nixos/custom/system/home-manager.nix
  custom.users.homeManagerUsers = [ "root" "user" ];
}
