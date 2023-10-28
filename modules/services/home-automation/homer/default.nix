{ config, inputs, ... }: {

  environment.mutable-files = {
    "/mnt/ha-store/homer/fonts" = {
      source = "${inputs.homer-theme}/assets/fonts";
      user = config.users.users.user.name;
      group = config.users.users.user.group;
    };

    "/mnt/ha-store/homer/custom.css" = {
      source = "${inputs.homer-theme}/assets/custom.css";
      user = config.users.users.user.name;
      group = config.users.users.user.group;
    };

    "/mnt/ha-store/homer/wallpaper-light.jpeg" = {
      source = "${inputs.homer-theme}/assets/wallpaper-light.jpeg";
      user = config.users.users.user.name;
      group = config.users.users.user.group;
    };

    "/mnt/ha-store/homer/config.yml" = {
      source = ./config.yml;
      user = config.users.users.user.name;
      group = config.users.users.user.group;
    };
  };
}
