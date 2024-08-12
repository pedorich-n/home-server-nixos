{ config, ... }: {
  systemd.tmpfiles.settings."90-zigbee2mqtt" = {
    "/mnt/store/home-automation/zigbee2mqtt/configuration.yaml" = {
      "C+" = {
        user = config.users.users.user.name;
        group = config.users.users.user.group;
        mode = "0755";
        argument = "${./configuration.yaml}";
      };
    };
  };
}
