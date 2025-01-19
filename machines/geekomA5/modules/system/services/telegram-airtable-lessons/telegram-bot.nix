{ config, ... }:
let
  user = config.users.users.user.name;
  group = config.users.users.user.group;
in
{
  services.telegram-lessons-bot = {
    enable = true;
    configFile = config.sops.secrets."telegram-airtable-lessons/telegram_bot.toml".path;
    inherit user group;
  };
}
