{ config, ... }: {
  environment.mutable-files = {
    "/mnt/ha-store/homer/config.yml" = {
      source = ./config.yml;
      user = config.users.users.user.name;
      inherit (config.users.users.user) group;
    };
  };
}
