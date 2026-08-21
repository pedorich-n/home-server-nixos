{
  config,
  lib,
  pkgs,
  ...
}:
let
  keyValueFomat = pkgs.formats.keyValue { };

  plh = config.sops.placeholder;

  mkResticSecrets = service: {
    "restic/${service}/environment" = {
      file = keyValueFomat.generate "restic-${service}.env" {
        AWS_ACCESS_KEY_ID = plh."restic/${service}/access_key_id";
        AWS_SECRET_ACCESS_KEY = plh."restic/${service}/secret_access_key";
      };
    };

    "restic/${service}/repository" = {
      file = pkgs.writeText "restic-repository-${service}" ''
        s3:${plh."restic/${service}/endpoint"}/${plh."restic/${service}/bucket_name"}
      '';
    };
  };

  resticServices = lib.attrNames config.services.restic.backups;
in
{
  sops.templates = lib.foldl' (acc: service: acc // (mkResticSecrets service)) { } resticServices;
}
