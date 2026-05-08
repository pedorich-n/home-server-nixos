{
  config,
  ...
}:
let
  user = config.users.users.user.name;
  group = config.users.users.user.group;

  portsCfg = config.custom.networking.ports.tcp.lessons-calendar-loader;
in
{
  custom = {
    networking.ports.tcp.lessons-calendar-loader = {
      port = 9000;
      openFirewall = false;
    };

    services.caddy.hosts."calendar-loader" = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
    };
  };

  services = {
    lessons-calendar-loader = {
      enable = true;
      configFile = config.sops.secrets."telegram-airtable-lessons/calendar_loader.toml".path;
      inherit user group;
    };

    lessons-calendar-loader-scheduler-cron = {
      enable = true;
      username = user;

      baseUrl = "http://127.0.0.1:${portsCfg.portStr}";

      schedules = {
        "3fde21a1-f908-420c-bba4-255446e89fab" = {
          dumpEvents = "0 17 * * Sun";
          # refreshToken = "Wed *-*-* 15:00:00";
        };
      };
    };

  };
}
