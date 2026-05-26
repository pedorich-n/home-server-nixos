{
  config,
  networkingLib,
  lib,
  pkgs,
  ...
}:
let
  backupFolder = "${config.services.jellyfin.dataDir}/data/backups";
  preparedBackupFolder = "${backupFolder}/prepared";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    jellyfin = {
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
          name = "jellyfin-backup-prepare";

          runtimeInputs = [
            pkgs.curl
            pkgs.jq
          ];
          text = ''
            token=$(cat ${config.sops.secrets."jellyfin/api/restic_key".path})

            backup_path=$(curl -s -X 'POST' \
              '${networkingLib.mkUrl "jellyfin"}/Backup/Create' \
              -H "Authorization: MediaBrowser Token=''${token}" \
              -H 'Content-Type: application/json' \
              -d '{"Metadata": true, "Trickplay": true, "Subtitles": true, "Database": true}' | jq -r '.Path')

            echo "Backup created at: $backup_path"

            mkdir -p "${preparedBackupFolder}"
            mv "''${backup_path}" "${preparedBackupFolder}/backup.zip"
          '';
        }
      );

      backupCleanupCommand = ''
        rm -r "${preparedBackupFolder}"
      '';
    };
  };
}
