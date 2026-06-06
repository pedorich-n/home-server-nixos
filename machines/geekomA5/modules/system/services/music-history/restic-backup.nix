{
  config,
  lib,
  pkgs,
  ...
}:
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    maloja =
      let
        backupFolder = "/mnt/store/music-history/maloja/data/backups";
        preparedBackupFolder = "${backupFolder}/prepared";
      in
      {
        paths = [
          preparedBackupFolder
        ];

        pruneOpts = [
          "--keep-daily 14"
          "--keep-weekly 4"
          "--keep-monthly 3"
        ];

        backupPrepareCommand = lib.getExe (
          pkgs.writeShellApplication {
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

              output=$(podman exec --user 1100:1100 --tty maloja /venv/bin/python -m maloja backup --targetfolder /data/backups/)
              filename=$(echo "''${output}" | ansi2txt | grep -oP '(?<=Backup created: ).*' | xargs basename)
              echo "Backup filename is ''${filename}"

              tar -xvzf "${backupFolder}/''${filename}" -C "${preparedBackupFolder}"
            '';
          }
        );

        backupCleanupCommand = ''
          rm -r "${preparedBackupFolder}"
          rm ${backupFolder}/*.tar.gz
        '';
      };

    #NOTE - See also global config at
    #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
    koito =
      let
        koitoDir = "/mnt/store/music-history/koito";
        backupFolder = "${koitoDir}/backups";
      in
      {
        paths = [
          backupFolder
        ];

        pruneOpts = [
          "--keep-daily 14"
          "--keep-weekly 4"
          "--keep-monthly 3"
        ];

        backupPrepareCommand = lib.getExe (
          pkgs.writeShellApplication {
            name = "koito-backup-prepare";
            runtimeInputs = with pkgs; [
              sqlite
            ];
            text = ''
              echo "Koito backup is stored at: ${backupFolder}"

              mkdir -p "${backupFolder}"

              sqlite3 ${koitoDir}/koito.db ".backup '${backupFolder}/koito-backup.db'"
            '';
          }
        );

        backupCleanupCommand = ''
          rm -r ${backupFolder}
        '';
      };
  };
}
