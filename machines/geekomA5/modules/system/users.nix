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
}
