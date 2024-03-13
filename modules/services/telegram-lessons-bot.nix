{ config, ... }:
let
  user = config.users.users.user.name;
  group = config.users.users.user.group;
in
{
  services = {

    ngrok = {
      enable = true;
      configFile = config.age.secrets.ngrok.path;
      inherit user group;
    };

    lessons-calendar-loader = {
      enable = true;
      configFile = config.age.secrets.calendar-loader-config-main.path;
      inherit user group;
    };

    lessons-calendar-loader-scheduler = {
      enable = true;
      inherit user group;

      baseUrl = "http://localhost:9000";

      schedules = {
        "26fc8d17-216b-4704-891e-023cc32bb068" = {
          dumpEvents = "Sun *-*-* 17:00:00";
          refreshToken = "Wed *-*-* 15:00:00";
        };
      };
    };

    telegram-lessons-bot = {
      enable = true;
      configFile = config.age.secrets.telegram-airtable-bot-config-main.path;
      inherit user group;
    };
  };
}
