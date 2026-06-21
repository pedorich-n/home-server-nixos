{
  config,
  lib,
  ...
}:
let
  dbBackupFolder = "/mnt/store/airtrail/postgresql/backup";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    airtrail = {
      paths = [
        dbBackupFolder
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];

      backupPrepareCommand = ''
        mkdir -p ${dbBackupFolder}
        set -o allexport; source ${config.sops.secrets."airtrail/postgresql.env".path}; set +o allexport

        ${lib.getExe config.virtualisation.podman.package} exec --tty airtrail-postgresql \
        pg_dumpall --username ''${POSTGRES_USER} --clean --if-exists > "${dbBackupFolder}/backup.sql"
      '';

      backupCleanupCommand = ''
        rm -r ${dbBackupFolder}
      '';
    };
  };
}
