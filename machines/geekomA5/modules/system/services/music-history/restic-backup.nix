{ config, lib, pkgs, ... }:
let
  backupFolder = "/mnt/store/music-history/maloja/data/backups";
  preparedBackupFolder = "${backupFolder}/prepared";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic.nix
  services.restic.backups = {
    maloja = {
      paths = [
        preparedBackupFolder
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 6"
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
    };
  };
}
