{ config, lib, pkgs, ... }:
let
  dbBackupFolder = "/mnt/store/immich/db-backup";

  package = pkgs.restic;
in
{
  environment.systemPackages = [ package ];

  services.restic.backups = {
    immich = {

      timerConfig = {
        OnCalendar = "*-*-* 02:00:00"; # Every day at 02:00
        Persistent = true;
      };

      paths = [
        "/mnt/external/immich-library/upload" # Original assets
        "/mnt/external/immich-library/library" # Organized assets
        "/mnt/store/immich/cache/thumbnails" # Thumbnails also include facial recongion, so it's better to keep it
        "/mnt/store/immich/cache/profile" # Profile pictures
        dbBackupFolder # DB backup
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 12"
        "--keep-yearly 2"
      ];

      extraBackupArgs = [
        "--tag auto"
      ];

      # NOTE: https://immich.app/docs/administration/backup-and-restore/
      backupPrepareCommand = ''
        mkdir -p ${dbBackupFolder}
        set -o allexport; source ${config.age.secrets.immich_compose_main.path}; set +o allexport

        ${lib.getExe config.virtualisation.podman.package} exec --tty immich-postgresql \
        pg_dumpall --username ''${DB_USERNAME} --clean --if-exists > "${dbBackupFolder}/backup.sql"
      '';

      environmentFile = config.age.secrets.immich_restic_environment.path;
      repositoryFile = config.age.secrets.immich_restic_repository.path;
      passwordFile = config.age.secrets.immich_restic_password.path;

      inherit package;
    };
  };
}
