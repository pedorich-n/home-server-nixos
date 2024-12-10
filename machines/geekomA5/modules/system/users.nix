{ pkgs, ... }: {
  users = {
    groups = {
      zigbee = { };
    };

    users = {
      root = {
        shell = pkgs.zsh;
      };

      user = {
        extraGroups = [ "zigbee" ];
        shell = pkgs.zsh;
      };
    };
  };

  #LINK - shared-modules/nixos/custom/system/users.nix
  custom.users.homeManagerUsers = [ "root" "user" ];
}
