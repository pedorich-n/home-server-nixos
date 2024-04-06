{ config, pkgs-unstable, ... }:
let
  user = config.users.users.user.name;
  group = config.users.users.user.group;
in
{
  services = {

    ngrok = {
      enable = true;
      package = pkgs-unstable.ngrok;
      settingsFile = config.age.secrets.ngrok.path;
    };

    lessons-calendar-loader = {
      enable = true;
      configFile = config.age.secrets.calendar_loader_config_main.path;
      inherit user group;
    };

    lessons-calendar-loader-scheduler = {
      enable = true;
      inherit user group;

      baseUrl = "http://localhost:9000";

      schedules = {
        "a7620a98-5378-4749-b73c-350e1dcc72b5" = {
          dumpEvents = "Sun *-*-* 17:00:00";
          # refreshToken = "Wed *-*-* 15:00:00";
        };
      };
    };

    telegram-lessons-bot = {
      enable = true;
      configFile = config.age.secrets.telegram_airtable_bot_config_main.path;
      inherit user group;
    };
  };
}
