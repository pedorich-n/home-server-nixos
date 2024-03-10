{ config, ... }:
{
  services.ngrok = {
    enable = true;
    configFile = config.age.secrets.ngrok-config.path;
    user = "user";
    group = "users";
  };

  services.lessons-calendar-loader = {
    enable = true;
    configFile = ./config_test.toml;
    user = "user";
    group = "users";
  };
}
