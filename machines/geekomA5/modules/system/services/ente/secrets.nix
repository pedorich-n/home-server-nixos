{ config, pkgs, networkingLib, ... }:
let
  yamlFormat = pkgs.formats.yaml { };
in
{
  sops.templates = {
    "ente/museum.yaml" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;
      file = yamlFormat.generate "museum-config.yaml" {
        internal = {
          admins = [ 1580559962386438 ];
          disable-registration = true;
        };
        apps = {
          accounts = networkingLib.mkUrl "ente-accounts";
        };
        webauthn = {
          rpid = config.custom.networking.domain;
          rporigins = [
            (networkingLib.mkUrl "ente-accounts")
          ];
        };

        key = {
          encryption = config.sops.placeholder."ente/encryption/key";
          hash = config.sops.placeholder."ente/encryption/hash";
        };
        db = {
          host = "ente-postgresql";
          port = 5432;
          name = config.sops.placeholder."ente/database/name";
          user = config.sops.placeholder."ente/database/username";
          password = config.sops.placeholder."ente/database/password";
        };
        s3 = {
          are_local_buckets = false;
          use_path_style_urls = true;
          # A hard-coded bucket name. See https://help.ente.io/self-hosting/administration/object-storage#bucket-configuration
          b2-eu-cen = {
            key = config.sops.placeholder."ente/storage/key_id";
            secret = config.sops.placeholder."ente/storage/key_secret";
            endpoint = networkingLib.mkUrl "storage";
            region = config.services.minio.region;
            bucket = config.sops.placeholder."ente/storage/bucket_name";
          };
        };
      };
    };
  };

}
