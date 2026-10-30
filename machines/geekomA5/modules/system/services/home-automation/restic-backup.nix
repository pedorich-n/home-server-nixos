{
  pkgs,
  lib,
  ...
}:
let
  rootStoreFolder = "/mnt/store/home-automation/homeassistant";
  dbBackupFolder = "${rootStoreFolder}/db-backup";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    homeassistant = {
      paths = lib.map (rel: "${rootStoreFolder}/${rel}") [
        "automations"
        "db-backup"
        "configuration"
        "custom_components"
        "deps"
        "local"
        "resources"
        ".storage"
        "themes"
        "www"
        "automations.yaml"
        "configuration.yaml"
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];

      backupPrepareCommand = lib.getExe (
        pkgs.writeShellApplication {
          name = "homeassistant-backup-prepare";
          runtimeInputs = with pkgs; [
            sqlite
          ];
          text = ''
            echo "Home Assistant DB backup is stored at: ${dbBackupFolder}"

            mkdir -p "${dbBackupFolder}"

            sqlite3 ${rootStoreFolder}/home-assistant_v2.db ".backup '${dbBackupFolder}/db-backup.sqlite'"
          '';
        }
      );

      backupCleanupCommand = ''
        rm -r "${dbBackupFolder}"
      '';
    };
  };
}
