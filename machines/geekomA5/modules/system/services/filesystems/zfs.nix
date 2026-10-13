{
  services.zfs.autoScrub = {
    enable = true;
    interval = "Thu *-*-* 04:00:00"; # Every Thursday at 04:00
  };

  services.sanoid = {
    enable = true;

    interval = "*-*-* *:00/15:00"; # At 00,15,30,45 mintues of every hour

    #LINK - machines/geekomA5/modules/system/hardware/filesystems/zfs-external.nix
    datasets = {
      "external/immich" = {
        autosnap = true;
        use_template = [ "default" ];
      };
      "external/papra" = {
        autosnap = true;
        use_template = [ "default" ];
      };
      "external/rustfs" = {
        autosnap = true;
        use_template = [ "default" ];
      };
      "external/data" = {
        autoprune = true;
        autosnap = true;
        daily = 14;
        frequently = 8; # 2 hours
        hourly = 24;
        monthly = 0;
        weekly = 0;
      };
    };

    templates.default = {
      autoprune = true;
      frequent_period = 15; # Minutes
      daily = 30;
      frequently = 12; # 3 hours
      hourly = 48;
      monthly = 0;
      weekly = 0;
    };
  };
}
