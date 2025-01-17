{ inputs, lib, ... }:
let
  secretsRoot = "${inputs.home-server-nixos-secrets}/sops/encrypted/geekomA5";

  sopsFilePathFor = filename: "${secretsRoot}/${filename}";

  envSecrets =
    let
      mkRelativePath = path: (lib.removePrefix "${secretsRoot}/" (builtins.unsafeDiscardStringContext path));
      mkSecretAttrName = path: lib.removeSuffix ".env" (mkRelativePath path);

      allEnvs = lib.filter (path: lib.hasSuffix ".env" path) (lib.filesystem.listFilesRecursive secretsRoot);
      mkEnv = path: {
        ${mkSecretAttrName path} = {
          name = mkRelativePath path;
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

      # "multiscrobbler/maloja/api_key" = { };
      # "multiscrobbler/spotify/client_id" = { };
      # "multiscrobbler/spotify/client_secret" = { };

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
    }
    // envSecrets;
  };
}
