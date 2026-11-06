{
  config,
  ...
}:
{
  systemd.tmpfiles.settings."90-obsidian-mirror" = {
    "/mnt/store/obsidian-mirror" = {
      "d" = {
        mode = "0750";
        user = config.users.users.obsidian-mirror.name;
        group = config.users.users.obsidian-mirror.group;
      };
    };
  };
}
