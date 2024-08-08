{ config, lib, pkgs, ... }:
let
  backupFolder = "/mnt/store/music-history/maloja/data/backups";
  preparedBackupFolder = "${backupFolder}/prepared";
in
{
  services.restic.backups = {
    maloja = {

      timerConfig = {
        OnCalendar = "*-*-* 02:30:00"; # Every day at 02:30
        Persistent = true;
      };

      paths = [
        preparedBackupFolder
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];

      extraBackupArgs = [
        "--tag auto"
      ];

      backupPrepareCommand = lib.getExe (pkgs.writeShellApplication {
        name = "maloja-backup-prepare";
        runtimeInputs = with pkgs; [
          gnutar
          gzip
          gnugrep
          coreutils
          colorized-logs
          config.virtualisation.podman.package
        ];
        text = ''
          mkdir -p "${preparedBackupFolder}"

          output=$(podman exec --tty maloja maloja backup --targetfolder /data/backups/)
          filename=$(echo "''${output}" | ansi2txt | grep -oP '(?<=Backup created: ).*' | xargs basename)
          echo "Backup filename is ''${filename}"

          tar -xvzf "${backupFolder}/''${filename}" -C "${preparedBackupFolder}"
        '';
      });

      backupCleanupCommand = ''
        rm -r "${preparedBackupFolder}"
        rm ${backupFolder}/*.tar.gz
      '';

      environmentFile = config.age.secrets.maloja_restic_environment.path;
      repositoryFile = config.age.secrets.maloja_restic_repository.path;
      passwordFile = config.age.secrets.maloja_restic_password.path;
    };
  };
}
