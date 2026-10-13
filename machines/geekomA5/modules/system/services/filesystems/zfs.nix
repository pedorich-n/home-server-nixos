{
  services.zfs.autoScrub = {
    enable = true;
    interval = "Thu *-*-* 04:00:00"; # Every Thursday at 04:00
  };

  services.sanoid = {
    enable = true;

    #LINK - machines/geekomA5/modules/system/hardware/filesystems/zfs-external.nix
    datasets = {
      "external/immich" = {
        autosnap = "yes";
        template = "default";
      };
      "external/papra" = {
        autosnap = "yes";
        template = "default";
      };
      "external/rustfs" = {
        autosnap = "yes";
        template = "default";
      };
      "external/data" = {
        autosnap = "yes";
        daily = 30;
        frequently = 0;
        hourly = 24;
        monthly = 0;
        weekly = 0;
      };
    };

    templates.default = {
      daily = 30;
      frequently = 12;
      hourly = 48;
      monthly = 0;
      weekly = 0;
    };
  };
}
