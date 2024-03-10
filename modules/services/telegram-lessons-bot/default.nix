{ config, ... }:
{
  services = {
    ngrok = {
      enable = true;
      configFile = config.age.secrets.ngrok-config.path;
      user = "user";
      group = "users";
    };

    lessons-calendar-loader = {
      enable = true;
      configFile = config.age.secrets.calendar-loader-config-test.path;
      user = "user";
      group = "users";
    };

    lessons-calendar-loader-scheduler = {
      enable = false;
      user = "user";
      group = "users";

      baseUrl = "http://localhost:9000";

      schedules = {
        "9f05cd56-902e-4915-b4d2-e32f7340f721" = "test";
      };
    };
  };
}
