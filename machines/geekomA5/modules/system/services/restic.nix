{ config, lib, ... }:
let
  dbBackupFolder = "/mnt/store/immich/db-backup";
in
{
  services.restic.backups = lib.mkIf config.systemd.services.arion-immich.enable {
    immich = {
      timerConfig = {
        OnCalendar = "*-*-* 02:00:00"; # Every day at 02:00
        Persistent = true;
      };

      paths = [
        "/mnt/external/immich-library/upload" # Original assets
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

      # See: https://immich.app/docs/administration/backup-and-restore/
      backupPrepareCommand = ''
        mkdir -p ${dbBackupFolder}
        ${lib.getExe config.virtualisation.podman.package} exec -t immich-postgres pg_dumpall --clean --if-exists --file "${dbBackupFolder}/backup.sql"
      '';

      # See https://www.arthurkoziel.com/restic-backups-b2-nixos/
      # TODO 
      # environmentFile = config.age.secrets."restic/env".path;
      # repositoryFile = config.age.secrets."restic/repo".path;
      # passwordFile = config.age.secrets."restic/password".path;
    };
  };
}
