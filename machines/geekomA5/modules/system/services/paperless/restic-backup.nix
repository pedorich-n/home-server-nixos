{ config, lib, ... }:
let
  dbBackupFolder = "/mnt/store/paperless/db-backup";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic.nix
  services.restic.backups = {
    paperless = {
      paths = [
        "/mnt/external/paperless-library/media" # Assets
        dbBackupFolder # DB backup
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 1"
      ];

      backupPrepareCommand = ''
        mkdir -p ${dbBackupFolder}
        set -o allexport; source ${config.age.secrets.paperless_compose.path}; set +o allexport

        ${lib.getExe config.virtualisation.podman.package} exec --tty paperless-postgresql \
        pg_dumpall --username ''${POSTGRES_USER} --clean --if-exists > "${dbBackupFolder}/backup.sql"
      '';
    };
  };
}
