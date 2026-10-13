{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  mirrorDir = "/tmp/grist-s3-mirror";
  mcConfigDir = "/tmp/grist-s3-mirror-mc";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups.grist = {
    paths = [
      "/mnt/store/grist/persist" # metadata: users, workspaces, ACL, sharing, etc + cache
      mirrorDir # mirror of the S3 bucket (canonical document content)
    ];

    pruneOpts = [
      "--keep-daily 14"
      "--keep-weekly 4"
      "--keep-monthly 3"
    ];

    backupPrepareCommand = lib.getExe (
      pkgs.writeShellApplication {
        name = "grist-backup-prepare";

        runtimeInputs = [ pkgs-unstable.rustfs-cli ];

        text = ''
          export MC_CONFIG_DIR=${mcConfigDir}
          mkdir -p "$MC_CONFIG_DIR"

          admin_ak=$(tr -d '\n' < ${config.sops.secrets."rustfs/admin/access_key".path})
          admin_sk=$(tr -d '\n' < ${config.sops.secrets."rustfs/admin/secret_key".path})

          rc alias set rustfs_local "http://127.0.0.1:${config.custom.networking.ports.tcp.rustfs.portStr}" "$admin_ak" "$admin_sk"

          mkdir -p ${mirrorDir}
          rc mirror --overwrite --remove rustfs_local/grist ${mirrorDir}
        '';
      }
    );

    backupCleanupCommand = ''
      rm -r ${mirrorDir} ${mcConfigDir}
    '';
  };
}
