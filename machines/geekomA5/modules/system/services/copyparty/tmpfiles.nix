{ config, ... }:
{
  systemd.tmpfiles.settings."90-copyparty-history" = {
    "/var/lib/copyparty/history" = {
      "d" = {
        mode = "0755";
        user = config.users.users.copyparty.name;
        group = config.users.users.copyparty.group;
      };
    };
  };
}
