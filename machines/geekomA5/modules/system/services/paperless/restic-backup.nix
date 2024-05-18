{ config, lib, pkgs, ... }:
let
  dbBackupFolder = "/mnt/store/paperless/db-backup";

  package = pkgs.restic;
in
{
  environment.systemPackages = [ package ];

  services.restic.backups = {
    paperless = {

      timerConfig = {
        OnCalendar = "*-*-* 02:30:00"; # Every day at 02:30
        Persistent = true;
      };

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

      extraBackupArgs = [
        "--tag auto"
      ];

      backupPrepareCommand = ''
        mkdir -p ${dbBackupFolder}
        set -o allexport; source ${config.age.secrets.paperless_compose.path}; set +o allexport

        ${lib.getExe config.virtualisation.podman.package} exec --tty paperless-postgresql \
        pg_dumpall --username ''${POSTGRES_USER} --clean --if-exists > "${dbBackupFolder}/backup.sql"
      '';

      environmentFile = config.age.secrets.paperless_restic_environment.path;
      repositoryFile = config.age.secrets.paperless_restic_repository.path;
      passwordFile = config.age.secrets.paperless_restic_password.path;

      inherit package;
    };
  };
}
