{ config, lib, ... }:
let
  backupFolder = "/mnt/store/paperless/export";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic.nix
  services.restic.backups = {
    paperless = {
      paths = [
        backupFolder
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 1"
      ];

      backupPrepareCommand = ''
        ${lib.getExe config.virtualisation.podman.package} exec --tty paperless-server \
        gosu paperless document_exporter /usr/src/paperless/export --delete
      '';

      backupCleanupCommand = ''
        find "${backupFolder}" -mindepth 1 -delete
      '';
    };
  };
}
