{
  pkgs,
  lib,
  ...
}:
let
  rootStoreFolder = "/mnt/store/papra";
  dbBackupFolder = "${rootStoreFolder}/backup";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    papra = {
      paths = [
        dbBackupFolder
        "/mnt/external/papra-library"
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];

      backupPrepareCommand = lib.getExe (
        pkgs.writeShellApplication {
          name = "papra-backup-prepare";
          runtimeInputs = with pkgs; [
            sqlite
          ];
          text = ''
            echo "Papra DB backup is stored at: ${dbBackupFolder}"

            mkdir -p "${dbBackupFolder}"

            sqlite3 ${rootStoreFolder}/data/db.sqlite ".backup '${dbBackupFolder}/db-backup.sqlite'"
          '';
        }
      );

      backupCleanupCommand = ''
        rm -r ${dbBackupFolder}
      '';
    };
  };
}
