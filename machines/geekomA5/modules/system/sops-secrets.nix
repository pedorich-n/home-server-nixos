{
  config,
  inputs,
  lib,
  ...
}:
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
      users = [
        "root"
        "user"
      ];

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

  traefikSecrets = {
    "cloudflare/api_tokens/traefik_acme" = {
      owner = config.users.users.traefik.name;
      group = config.users.users.traefik.group;
    };
  };

  autheliaSecrets =
    let
      paths = [
        "authelia/jwt_secret"
        "authelia/storage_encryption_key"
        "authelia/ldap/password"

        "authelia/oidc/hmac_secret"

        "authelia/oidc/audiobookshelf/client_id"
        "authelia/oidc/audiobookshelf/client_secret_hashed"

        "authelia/oidc/grist/client_id"
        "authelia/oidc/grist/client_secret_hashed"

        "authelia/oidc/homeassistant/client_id"
        "authelia/oidc/homeassistant/client_secret_hashed"

        "authelia/oidc/immich/client_id"
        "authelia/oidc/immich/client_secret_hashed"

        "authelia/oidc/paperless/client_id"
        "authelia/oidc/paperless/client_secret_hashed"
        "authelia/oidc/paperless/client_secret_raw"
      ];

      mkSecret = path: {
        ${path} = {
          owner = config.services.authelia.instances.main.user;
          inherit (config.services.authelia.instances.main) group;
        };
      };

      extraSecrets = {
        "authelia/oidc/jwks.key" = {
          sopsFile = sopsFilePathFor "authelia/oidc/jwks.key";
          format = "binary";
          owner = config.services.authelia.instances.main.user;
          inherit (config.services.authelia.instances.main) group;
        };
      };

    in
    (lib.foldl' (acc: path: acc // (mkSecret path)) { } paths) // extraSecrets;

  lldapSecrets =
    let
      paths = [
        "lldap/key_seed"
        "lldap/jwt_secret"
        "lldap/users/admin/password"
      ];

      mkSecret = path: {
        ${path} = {
          owner = config.users.users.lldap.name;
          group = config.users.users.lldap.group;
        };
      };

    in
    lib.foldl' (acc: path: acc // (mkSecret path)) { } paths;

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

        "ente/encryption/key" = { };
        "ente/encryption/hash" = { };
        "ente/jwt/secret" = { };
        "ente/storage/bucket_name" = { };
        "ente/storage/key_id" = { };
        "ente/storage/key_secret" = { };
        "ente/database/name" = { };
        "ente/database/username" = { };
        "ente/database/password" = { };

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

        "tailscale/oauth_clients/server/id" = { };
        "tailscale/oauth_clients/server/secret" = { };
        "tailscale/oauth_clients/initrd/id" = { };
        "tailscale/oauth_clients/initrd/secret" = { };

        "paperless/client_id" = { };
        "paperless/client_secret" = { };

        "renovate/github_app_private_key" = {
          sopsFile = sopsFilePathFor "renovate/github_renovate_app.pem";
          format = "binary";
          owner = config.users.users.renovate.name;
          group = config.users.users.renovate.group;
        };

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
      (lib.mkIf config.services.lldap.enable lldapSecrets)
      (lib.mkIf config.services.authelia.instances.main.enable autheliaSecrets)
      (lib.mkIf (config.services ? ngrok && config.services.ngrok.enable) ngrokSecrets)
      (lib.mkIf (config.services ? playit && config.services.playit.enable) playitSecrets)
      (lib.mkIf config.services.traefik.enable traefikSecrets)
    ];
  };
}
