{ config, ... }: {
  environment.mutable-files = {
    "/mnt/ha-store/zigbee2mqtt/configuration.yaml" = {
      source = ./configuration.yaml;
      user = config.users.users.user.name;
      inherit (config.users.users.user) group;
    };
  };
}
