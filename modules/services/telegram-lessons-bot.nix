{ config, ... }: {
  services.telegram-lessons-bot = {
    enable = true;
    user = config.users.users.user.name;
    inherit (config.users.users.user) group;
    settingsFile = config.age.secrets.telegram-airtable-bot-config.path;
  };
}



