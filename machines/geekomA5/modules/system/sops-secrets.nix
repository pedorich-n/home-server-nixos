{
  config,
  inputs,
  lib,
  ...
}:
let
  mapMergeAttrsList = f: list: lib.mergeAttrsList (lib.map f list);

  secretsRoot = "${inputs.home-server-nixos-secrets}/sops/encrypted/${config.networking.hostName}";
  sopsFilePathFor = filePath: "${secretsRoot}/${filePath}";

  # Decrypts all .env files recursively found in the secrets root as is, without extracting specific keys
  envSecrets =
    let
      mkRelativePath = absPath: (lib.removePrefix "${secretsRoot}/" (builtins.unsafeDiscardStringContext absPath));

      allEnvPaths = lib.filter (p: lib.hasSuffix ".env" p) (lib.filesystem.listFilesRecursive secretsRoot);
      mkEnv = absPath: {
        ${mkRelativePath absPath} = {
          sopsFile = absPath;
          format = "dotenv";
          key = "";
        };
      };
    in
    mapMergeAttrsList mkEnv allEnvPaths;

  resticSecrets =
    let
      services = builtins.attrNames config.services.restic.backups;

      mkResticSecrets = service: {
        "restic/${service}/password" = { };
        "restic/${service}/repository" = { };
      };
    in
    mapMergeAttrsList mkResticSecrets services;

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
    mapMergeAttrsList mkUserPasswordSecret users;

  acmeSecrets = {
    "cloudflare/api_tokens/acme" = {
      owner = config.users.users.acme.name;
      group = config.security.acme.certs.local.group;
    };
  };

  autheliaSecrets =
    let
      secrets = [
        "authelia/jwt_secret"
        "authelia/session_secret"
        "authelia/storage_encryption_key"
        "authelia/redis/password"

        "authelia/smtp/username"
        "authelia/smtp/password"

        "authelia/oidc/hmac_secret"

        "authelia/oidc/audiobookshelf/client_id"
        "authelia/oidc/audiobookshelf/client_secret_hashed"

        "authelia/oidc/grist/client_id"
        "authelia/oidc/grist/client_secret_hashed"

        "authelia/oidc/homeassistant/client_id"
        "authelia/oidc/homeassistant/client_secret_hashed"

        "authelia/oidc/immich/client_id"
        "authelia/oidc/immich/client_secret_hashed"

        "authelia/oidc/jellyfin/client_id"
        "authelia/oidc/jellyfin/client_secret_hashed"

        "authelia/oidc/librechat/client_id"
        "authelia/oidc/librechat/client_secret_hashed"

        "authelia/oidc/paperless/client_id"
        "authelia/oidc/paperless/client_secret_hashed"
        "authelia/oidc/paperless/client_secret_raw"

        "authelia/oidc/shelfmark/client_id"
        "authelia/oidc/shelfmark/client_secret_hashed"

        "authelia/oidc/forgejo/client_id"
        "authelia/oidc/forgejo/client_secret_hashed"

        "authelia/oidc/gitea-mirror/client_id"
        "authelia/oidc/gitea-mirror/client_secret_hashed"

        "authelia/oidc/trek/client_id"
        "authelia/oidc/trek/client_secret_hashed"

        "authelia/oidc/olivetin/client_id"
        "authelia/oidc/olivetin/client_secret_hashed"
        "authelia/oidc/olivetin/client_secret_raw"

        "authelia/oidc/airtrail/client_id"
        "authelia/oidc/airtrail/client_secret_hashed"
      ];

      mkSecret = secret: {
        ${secret} = {
          owner = config.services.authelia.instances.main.user;
          group = config.services.authelia.instances.main.group;
        };
      };

      extraSecrets = {
        "authelia/oidc/jwks.key" = {
          sopsFile = sopsFilePathFor "authelia/oidc/jwks.key";
          format = "binary";
          owner = config.services.authelia.instances.main.user;
          group = config.services.authelia.instances.main.group;
        };
      };

    in
    (mapMergeAttrsList mkSecret secrets) // extraSecrets;

  lldapSecrets =
    let
      secrets = [
        "lldap/key_seed"
        "lldap/jwt_secret"

        "lldap/users/admin/username"
        "lldap/users/admin/email"
        "lldap/users/admin/password"

        "lldap/users/authelia/username"
        "lldap/users/authelia/email"
        "lldap/users/authelia/password"

        "lldap/users/jellyfin/username"
        "lldap/users/jellyfin/email"
        "lldap/users/jellyfin/password"

        "lldap/users/user_1/username"
        "lldap/users/user_1/displayname"
        "lldap/users/user_1/email"
        "lldap/users/user_1/password"

        "lldap/users/jksv/username"
        "lldap/users/jksv/email"
        "lldap/users/jksv/password"
      ];

      mkSecret = secret: {
        ${secret} = {
          owner = config.users.users.lldap.name;
          group = config.users.users.lldap.group;
        };
      };

    in
    mapMergeAttrsList mkSecret secrets;

  redisAutheliaSecrets =
    let
      secrets = [
        "redis/authelia/password"
      ];

      mkSecret = secret: {
        ${secret} = {
          owner = config.services.redis.servers.authelia.user;
          group = config.services.redis.servers.authelia.group;
        };
      };
    in
    mapMergeAttrsList mkSecret secrets;

  mbsyncSecrets =
    let
      mkSecret = account: {
        "mbsync/accounts/${account}/email" = { };
        "mbsync/accounts/${account}/password" = { };
        "mbsync/accounts/${account}/imap" = { };
      };

      # 4 accounts: email_1, email_2, ...
      accounts = lib.map (i: "email_${toString i}") (lib.range 1 4);
    in
    mapMergeAttrsList mkSecret accounts;

  forgejoSecrets =
    let
      secrets = [
        "forgejo/secrets/internal_token"
        "forgejo/secrets/secret_key"
      ];

      mkSecret = secret: {
        ${secret} = {
          owner = config.services.forgejo.user;
          group = config.services.forgejo.group;
        };
      };
    in
    mapMergeAttrsList mkSecret secrets;

  cloudflaredSecrets = {
    "cloudflared/n8n_tunnel_credentials" = {
      sopsFile = sopsFilePathFor "cloudflared/n8n_credentials_json.txt";
      format = "binary";
    };

    "cloudflared/couchdb_tunnel_credentials" = {
      sopsFile = sopsFilePathFor "cloudflared/couchdb_credentials_json.txt";
      format = "binary";
    };
  };

  netdataSecrets =
    let
      secrets = [
        "netdata/notifications/telegram/bot_token"
        "netdata/notifications/telegram/recipient"
        "netdata/prometheus/flyio/token"
      ];

      mkSecret = secret: {
        ${secret} = {
          owner = config.services.netdata.user;
          group = config.services.netdata.group;
        };
      };
    in
    mapMergeAttrsList mkSecret secrets;

  seaweedfsSecrets =
    let
      mkS3Credentials = user: [
        "seaweedfs/${user}/access_key"
        "seaweedfs/${user}/secret_key"
      ];

      s3Users = [
        "admin"
        "grist"
      ];

      secrets = lib.flatten (lib.map mkS3Credentials s3Users);

      mkSecret = secret: {
        ${secret} = {
          owner = config.users.users.seaweedfs.name;
          group = config.users.users.seaweedfs.group;
        };
      };
    in
    mapMergeAttrsList mkSecret secrets;

  sabnzbdSecrets =
    let
      mkSecret = secret: {
        ${secret} = {
          owner = config.services.sabnzbd.user;
          group = config.services.sabnzbd.group;
        };
      };
      secrets = [
        "sabnzbd/api_key"
        "sabnzbd/nzb_key"
        "sabnzbd/servers/blocknews/username"
        "sabnzbd/servers/blocknews/password"
        "sabnzbd/servers/thundernews/username"
        "sabnzbd/servers/thundernews/password"
      ];
    in
    mapMergeAttrsList mkSecret secrets;

  tombSecrets =
    let
      mkSecret = secret: {
        ${secret} = {
          sopsFile = sopsFilePathFor secret;
          format = "binary";

          group = config.users.groups.tomb.name;
        };
      };

      secrets = [
        "tomb/main.key"
      ];
    in
    mapMergeAttrsList mkSecret secrets;

  couchdbSecrets =
    let
      secrets = [
        "couchdb/users/admin/username"
        "couchdb/users/admin/password"
        "couchdb/users/obsidian_livesync/username"
        "couchdb/users/obsidian_livesync/password"
        "couchdb/db/obsidian_livesync/name"
      ];

      mkSecret = secret: {
        ${secret} = {
          owner = config.services.couchdb.user;
          group = config.services.couchdb.group;
        };
      };
    in
    mapMergeAttrsList mkSecret secrets;
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
          key = "";
        };

        "immich/api/immich-go/key" = { };

        "mosquitto/users/homeassistant/password" = { };
        "mosquitto/users/zigbee2mqtt/password" = { };
        "mosquitto/users/iot-device/password" = { };
        "mosquitto/users/observer/password" = { };

        "music-history/maloja/api_keys/multiscrobbler" = { };
        "music-history/multiscrobbler/maloja/api_key" = { };
        "music-history/multiscrobbler/koito/username" = { };
        "music-history/multiscrobbler/koito/api_key" = { };
        "music-history/multiscrobbler/spotify/client_id" = { };
        "music-history/multiscrobbler/spotify/client_secret" = { };

        "paperless/smtp/username" = { };

        "tailscale/oauth_clients/server/id" = { };
        "tailscale/oauth_clients/server/secret" = { };
        "tailscale/oauth_clients/initrd/id" = { };
        "tailscale/oauth_clients/initrd/secret" = { };

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

        "playit/secret" = {
          sopsFile = sopsFilePathFor "playit/secret.toml";
          format = "binary";
        };

        "jellyfin/api/restic_key" = { };

        "sonarr/api/key" = { };
        "radarr/api/key" = { };
        "prowlarr/api/key" = { };
      }
      osUserPasswords
      envSecrets
      resticSecrets
      acmeSecrets
      seaweedfsSecrets
      tombSecrets
      (lib.mkIf config.custom.services.mbsync.enable mbsyncSecrets)
      (lib.mkIf config.services.lldap.enable lldapSecrets)
      (lib.mkIf config.services.authelia.instances.main.enable autheliaSecrets)
      (lib.mkIf config.services.redis.servers.authelia.enable redisAutheliaSecrets)
      (lib.mkIf config.services.forgejo.enable forgejoSecrets)
      (lib.mkIf config.services.cloudflared.enable cloudflaredSecrets)
      (lib.mkIf config.services.netdata.enable netdataSecrets)
      (lib.mkIf config.services.sabnzbd.enable sabnzbdSecrets)
      (lib.mkIf config.services.couchdb.enable couchdbSecrets)
    ];
  };
}
