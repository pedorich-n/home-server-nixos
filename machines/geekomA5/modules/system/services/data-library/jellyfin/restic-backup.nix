{
  config,
  lib,
  ...
}:
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    jellyfin = {
      paths = [
        "/mnt/store/data-library/jellyfin/config/config"
        "/mnt/store/data-library/jellyfin/config/data"
        "/mnt/store/data-library/jellyfin/config/plugins"
        "/mnt/store/data-library/jellyfin/config/root"
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];

      backupPrepareCommand = ''
        ${lib.getExe' config.systemd.package "systemctl"} stop jellyfin.service
      '';

      backupCleanupCommand = ''
        ${lib.getExe' config.systemd.package "systemctl"} start --no-block jellyfin.service
      '';
    };
  };
}
