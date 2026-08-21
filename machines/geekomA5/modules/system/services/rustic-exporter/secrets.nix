{
  config,
  pkgs,
  lib,
  ...
}:
let
  mkConfigEntry = name: {
    inherit name;
    repository = "opendal:s3";
    password = config.sops.placeholder."restic/${name}/password";
    options = {
      endpoint = config.sops.placeholder."restic/${name}/endpoint";
      access_key_id = config.sops.placeholder."restic/${name}/access_key_id";
      secret_access_key = config.sops.placeholder."restic/${name}/secret_access_key";
      bucket = config.sops.placeholder."restic/${name}/bucket_name";
      region = "auto"; # Not used by Backblaze B2, but required by the S3 API
      root = "/";
    };
  };

  excludedBackups = {
    # These services have been retired, so they have no new snapshots.
    # But for archival purposes they're still listed in the secrets and configs.
    maloja = true;
    paperless = true;
  };
  resticBackups = lib.filter (backup: !excludedBackups.${backup} or false) (lib.attrNames config.services.restic.backups);
in
{
  sops.templates = {
    "rustic-exporter/config.toml" = {
      restartUnits = [
        config.systemd.services.rustic-exporter.name
      ];
      file = pkgs.writers.writeTOML "rustic-exporter-config.toml" {
        backup = lib.map mkConfigEntry resticBackups;
      };
    };
  };
}
