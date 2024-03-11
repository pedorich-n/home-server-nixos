{ config, inputs, ... }:
let
  permissions = {
    mode = "440";
    owner = config.users.users.user.name;
    group = config.users.users.user.group;
  };

  pathFor = file: "${inputs.home-server-nixos-secrets}/encrypted/${file}";
in
{
  age = {
    secrets = {
      # TODO: write a function to traverse files rather than doing it manually
      root-password = {
        file = pathFor "root_password.txt.age";
      };
      user-password = {
        file = pathFor "user_password.txt.age";
      };
      mariadb-password = {
        file = pathFor "mariadb_password.txt.age";
      } // permissions;
      mariadb-root-password = {
        file = pathFor "mariadb_root_password.txt.age";
      } // permissions;
      mariadb-user = {
        file = pathFor "mariadb_user.txt.age";
      } // permissions;
      tailscale-key = {
        file = pathFor "tailscale_key.txt.age";
      } // permissions;
      mosquitto-passwords = {
        file = pathFor "mosquitto_passwords_hashed.txt.age";
      } // permissions;
      zigbee2mqtt-secrets = {
        file = pathFor "zigbee2mqtt_secrets.yaml.age";
      } // permissions;
      ha-secrets = {
        file = pathFor "ha_secrets.yaml.age";
      } // permissions;
      telegram-airtable-bot-config = {
        file = pathFor "telegram_airtable_bot_config_main.yaml.age";
      } // permissions;
      calendar-loader-config-test = {
        file = pathFor "calendar_loader_config_test.toml.age";
        name = "calendar_loader_config_test.toml";
      } // permissions;
      calendar-loader-config-main = {
        name = "calendar_loader_config_main.toml";
        file = pathFor "calendar_loader_config_main.toml.age";
      } // permissions;
      playit-secret = {
        file = pathFor "playit_secret.toml.age";
        mode = "440";
        owner = "playit";
        group = "playit";
      };
      server-check-config = {
        file = pathFor "server_check_config.toml.age";
      };
      ngrok-config = {
        file = pathFor "ngrok.yaml.age";
      } // permissions;
    };
  };
}
