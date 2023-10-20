{ config, inputs, ... }:
let
  permissions = {
    mode = "440";
    owner = config.users.users.user.name;
    inherit (config.users.users.user) group;
  };

  pathFor = file: "${inputs.home-server-nixos-secrets}/encrypted/${file}";
in
{
  age = {
    secrets = {
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
      telegram-airtable-bot-config = {
        file = pathFor "telegram_airtable_bot_config_main.yaml.age";
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
      duckdns-key = {
        file = pathFor "duckdns_key.txt.age";
      } // permissions;
    };
  };
}
