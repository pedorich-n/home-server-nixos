{
  config,
  lib,
  ...
}:
let
  dbBackupFolder = "/mnt/store/home-automation/homeassistant/db-backup";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    homeassistant = {
      paths = lib.map (rel: "/mnt/store/home-automation/homeassistant/${rel}") [
        "automations"
        "db-backup"
        "configuration"
        "custom_components"
        "deps"
        "local"
        "resources"
        ".storage"
        "themes"
        "ui_lovelace_minimalist"
        "www"
        "automations.yaml"
        "configuration.yaml"
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];

      backupPrepareCommand = ''
        mkdir -p "${dbBackupFolder}"
        set -o allexport; source ${config.sops.secrets."home-automation/postgresql.env".path}; set +o allexport

        ${lib.getExe config.virtualisation.podman.package} exec --tty homeassistant-postgresql \
        pg_dumpall --username ''${POSTGRES_USER} --clean --if-exists > "${dbBackupFolder}/backup.sql"
      '';

      backupCleanupCommand = ''
        rm -r "${dbBackupFolder}"
      '';
    };
  };
}
