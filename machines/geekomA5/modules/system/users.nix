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
        extraGroups = [ "zigbee" "render" ];
        shell = pkgs.zsh;
      };
    };
  };

  #LINK - shared-modules/nixos/custom/system/home-manager.nix
  custom.users.homeManagerUsers = [ "root" "user" ];
}
