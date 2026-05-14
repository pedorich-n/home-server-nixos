{
  config,
  pkgs,
  ...
}:
{
  sops.templates = {
    # See https://github.com/seaweedfs/seaweedfs/wiki/S3-Credentials#single-bucket-full-access
    "seaweedfs/s3-config.json" = {
      file = pkgs.writers.writeJSON "seaweedfs-s3-config-template.json" {
        identities = [
          {
            name = "admin";
            credentials = [
              {
                accessKey = config.sops.placeholder."seaweedfs/admin/access_key";
                secretKey = config.sops.placeholder."seaweedfs/admin/secret_key";
              }
            ];
            actions = [ "Admin" ];
          }
          {
            name = "grist";
            credentials = [
              {
                accessKey = config.sops.placeholder."seaweedfs/grist/access_key";
                secretKey = config.sops.placeholder."seaweedfs/grist/secret_key";
              }
            ];
            actions = [
              "Read:grist"
              "Write:grist"
              "List:grist"
              "Tagging:grist"
              "Versioning:grist"
            ];
          }
          {
            name = "ente";
            credentials = [
              {
                accessKey = config.sops.placeholder."seaweedfs/ente/access_key";
                secretKey = config.sops.placeholder."seaweedfs/ente/secret_key";
              }
            ];
            actions = [
              "Read:ente"
              "Write:ente"
              "List:ente"
              "Tagging:ente"
            ];
          }
        ];
      };
    };
  };
}
