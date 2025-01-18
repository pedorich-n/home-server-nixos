{ inputs, lib, ... }:
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


in
{
  sops = {
    defaultSopsFile = sopsFilePathFor "secrets.yaml";

    age = {
      generateKey = true;
    };

    secrets = {
      "os_passwords/root" = {
        neededForUsers = true;
      };
      "os_passwords/user" = {
        neededForUsers = true;
      };

      "apprise/urls/telegram" = { };

      "home-automation/homeassistant_secrets.yaml" = {
        sopsFile = sopsFilePathFor "home-automation/homeassistant_secrets.yaml";
        mode = "444"; # FIXME: figure out a way to idmap mount the file
        key = "";
      };
      "home-automation/zigbee2mqtt_secrets.yaml" = {
        sopsFile = sopsFilePathFor "home-automation/zigbee2mqtt_secrets.yaml";
        mode = "444"; # FIXME: figure out a way to idmap mount the file
        key = "";
      };
      "home-automation/mosquitto_passwords.txt" = {
        sopsFile = sopsFilePathFor "home-automation/mosquitto_passwords.txt";
        mode = "444"; # FIXME: figure out a way to idmap mount the file
        format = "binary";
      };

      "music-history/maloja/api_keys/multiscrobbler" = { };
      "music-history/multiscrobbler/maloja/api_key" = { };
      "music-history/multiscrobbler/spotify/client_id" = { };
      "music-history/multiscrobbler/spotify/client_secret" = { };

      "restic/grist/password" = { };
      "restic/grist/repository" = { };
      "restic/homeassistant/password" = { };
      "restic/homeassistant/repository" = { };
      "restic/immich/password" = { };
      "restic/immich/repository" = { };
      "restic/maloja/password" = { };
      "restic/maloja/repository" = { };
      "restic/paperless/password" = { };
      "restic/paperless/repository" = { };

      "tailscale/key" = { };
    }
    // envSecrets;
  };
}
