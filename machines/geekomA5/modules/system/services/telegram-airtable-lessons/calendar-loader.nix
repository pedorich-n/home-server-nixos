{ config, networkingLib, ... }:
let
  user = config.users.users.user.name;
  group = config.users.users.user.group;

  portsCfg = config.custom.networking.ports.tcp.lessons-calendar-loader;
in
{
  custom.networking.ports.tcp.lessons-calendar-loader = { port = 9000; openFirewall = false; };

  services = {
    lessons-calendar-loader = {
      enable = true;
      configFile = config.sops.secrets."telegram-airtable-lessons/calendar_loader.toml".path;
      inherit user group;
    };

    lessons-calendar-loader-scheduler-cron = {
      enable = true;
      username = user;

      baseUrl = "http://localhost:${portsCfg.portStr}";

      schedules = {
        "a7620a98-5378-4749-b73c-350e1dcc72b5" = {
          dumpEvents = "0 17 * * Sun";
          # refreshToken = "Wed *-*-* 15:00:00";
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.calendar-loader-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "calendar-loader"}`)";
        service = "calendar-loader-secure";
      };

      services.calendar-loader-secure = {
        loadBalancer.servers = [{ url = "http://localhost:${portsCfg.portStr}"; }];
      };
    };
  };
}
