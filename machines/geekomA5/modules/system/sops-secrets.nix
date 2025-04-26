{ config, inputs, lib, ... }:
let
  secretsRoot = "${inputs.home-server-nixos-secrets}/sops/encrypted/geekomA5";

  sopsFilePathFor = filename: "${secretsRoot}/${filename}";

  envSecrets =
    let
      mkRelativePath = path: (lib.removePrefix "${secretsRoot}/" (builtins.unsafeDiscardStringContext path));

      allEnvs = lib.filter (path: lib.hasSuffix ".env" path) (lib.filesystem.listFilesRecursive secretsRoot);
      mkEnv = path: {
        ${mkRelativePath path} = {
          sopsFile = path;
          format = "dotenv";
          key = "";
        };
      };
    in
    lib.foldl' (acc: path: acc // mkEnv path) { } allEnvs;

  ngrokSecrets =
    let
      paths = [
        "ngrok/token"
        "ngrok/tunnels/telegram-airtable-lessons/domain"
        "ngrok/tunnels/telegram-airtable-lessons/allow_emails/1"
        "ngrok/tunnels/telegram-airtable-lessons/allow_emails/2"
      ];

      mkNgrokSecret = path: {
        ${path} = {
          owner = config.services.ngrok.user;
          inherit (config.services.ngrok) group;
        };
      };

    in
    lib.foldl' (acc: path: acc // (mkNgrokSecret path)) { } paths;

  resticSecrets =
    let
      services = builtins.attrNames config.services.restic.backups;

      mkResticSecrets = service: {
        "restic/${service}/password" = { };
        "restic/${service}/repository" = { };
      };
    in
    lib.foldl' (acc: service: acc // (mkResticSecrets service)) { } services;

  osUserPasswords =
    let
      users = [ "root" "user" ];

      mkUserPasswordSecret = user: {
        "os_passwords/${user}" = {
          neededForUsers = true;
        };
      };

    in
    lib.foldl' (acc: user: acc // (mkUserPasswordSecret user)) { } users;

  playitSecrets = {
    "playit/secret" = {
      sopsFile = sopsFilePathFor "playit/secret.toml";
      format = "binary";
      owner = config.services.playit.user;
      group = config.services.playit.group;
    };
  };

  stepCaSecrets =
    let
      mkStepCaSecret = args: {
        owner = config.users.users.step-ca.name;
        group = config.users.users.step-ca.group;
      } // args;
    in
    {
      "step-ca/intermediate/certificate" = mkStepCaSecret {
        sopsFile = sopsFilePathFor "step-ca/intermediate/ca.crt";
        format = "binary";
      };

      "step-ca/intermediate/key" = mkStepCaSecret {
        sopsFile = sopsFilePathFor "step-ca/intermediate/ca.key";
        format = "binary";
      };

      "step-ca/intermediate/password" = mkStepCaSecret { };

      "step-ca/root/certificate" = mkStepCaSecret {
        sopsFile = sopsFilePathFor "step-ca/root/ca.crt";
        format = "binary";
      };
    };

in
{
  sops = {
    defaultSopsFile = sopsFilePathFor "secrets.yaml";

    # Required to make the Podman mounts with idmap work, as ramfs doesn't support idmap
    useTmpfs = true;

    age = {
      generateKey = true;
    };

    secrets = lib.mkMerge [
      {
        "apprise/urls/telegram" = { };

        "home-automation/homeassistant_secrets.yaml" = {
          sopsFile = sopsFilePathFor "home-automation/homeassistant_secrets.yaml";
          owner = config.users.users.user.name;
          group = config.users.users.user.group;
          key = "";
        };
        "home-automation/zigbee2mqtt_secrets.yaml" = {
          sopsFile = sopsFilePathFor "home-automation/zigbee2mqtt_secrets.yaml";
          owner = config.users.users.user.name;
          group = config.users.users.user.group;
          key = "";
        };
        "home-automation/mosquitto_passwords.txt" = {
          sopsFile = sopsFilePathFor "home-automation/mosquitto_passwords.txt";
          owner = config.users.users.user.name;
          group = config.users.users.user.group;
          format = "binary";
        };

        "music-history/maloja/api_keys/multiscrobbler" = { };
        "music-history/multiscrobbler/maloja/api_key" = { };
        "music-history/multiscrobbler/spotify/client_id" = { };
        "music-history/multiscrobbler/spotify/client_secret" = { };

        "tailscale/key" = { };

        "telegram-airtable-lessons/calendar_loader.toml" = {
          sopsFile = sopsFilePathFor "telegram-airtable-lessons/calendar_loader.toml";
          format = "binary";
          owner = config.users.users.user.name;
          group = config.users.users.user.group;
        };
        "telegram-airtable-lessons/telegram_bot.toml" = {
          sopsFile = sopsFilePathFor "telegram-airtable-lessons/telegram_bot.toml";
          format = "binary";
          owner = config.users.users.user.name;
          group = config.users.users.user.group;
        };
      }
      osUserPasswords
      envSecrets
      resticSecrets
      (lib.mkIf (config.services ? ngrok && config.services.ngrok.enable) ngrokSecrets)
      (lib.mkIf (config.services ? playit && config.services.playit.enable) playitSecrets)
      (lib.mkIf config.services.step-ca.enable stepCaSecrets)
    ];
  };
}
