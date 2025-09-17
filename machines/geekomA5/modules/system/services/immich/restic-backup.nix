{ config, lib, ... }:
let
  dbBackupFolder = "/mnt/store/immich/db-backup";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic.nix
  services.restic.backups = {
    immich = {
      paths = [
        "/mnt/external/immich-library/upload" # Original assets
        "/mnt/external/immich-library/library" # Organized assets
        "/mnt/store/immich/cache/thumbnails" # Thumbnails also include facial recognition, so it's better to keep it
        "/mnt/store/immich/cache/profile" # Profile pictures
        dbBackupFolder # DB backup
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 12"
        "--keep-yearly 1"
      ];

      # NOTE: https://immich.app/docs/administration/backup-and-restore/
      backupPrepareCommand = ''
        mkdir -p ${dbBackupFolder}
        set -o allexport; source ${config.sops.secrets."immich/postgresql.env".path}; set +o allexport

        ${lib.getExe config.virtualisation.podman.package} exec --tty immich-postgresql \
        pg_dumpall --username ''${POSTGRES_USER} --clean --if-exists > "${dbBackupFolder}/backup.sql"
      '';

      backupCleanupCommand = ''
        rm -r ${dbBackupFolder}
      '';
    };
  };
}
