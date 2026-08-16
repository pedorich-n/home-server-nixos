{
  config,
  pkgs,
  lib,
  ...
}:
let
  mkConfigEntry =
    name:
    let
      slug = lib.toLower name;
    in
    {
      inherit name;
      repository = "opendal:s3";
      password = config.sops.placeholder."restic/${slug}/password";
      options = {
        endpoint = config.sops.placeholder."restic/${slug}/endpoint";
        access_key_id = config.sops.placeholder."restic/${slug}/access_key_id";
        secret_access_key = config.sops.placeholder."restic/${slug}/secret_access_key";
        bucket = config.sops.placeholder."restic/${slug}/bucket_name";
        region = "auto"; # Not used by Backblaze B2, but required by the S3 API
        root = "/";
      };
    };
in
{
  sops.templates = {
    "rustic-exporter/config.toml" = {
      file = pkgs.writers.writeTOML "rustic-exporter-config.toml" {
        backup = [
          (mkConfigEntry "Audiobookshelf")
          (mkConfigEntry "HomeAssistant")
        ];
      };
    };
  };
}
