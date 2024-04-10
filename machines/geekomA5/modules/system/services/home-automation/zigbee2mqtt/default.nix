{ config, ... }: {
  environment.mutable-files = {
    "/mnt/store/home-automation/zigbee2mqtt/configuration.yaml" = {
      source = ./configuration.yaml;
      user = config.users.users.user.name;
      group = config.users.users.user.group;
    };
  };
}
