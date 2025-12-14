{ config, ... }:
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    manual-backup = {
      paths = [
        config.custom.manual-backup.root
      ];

      exclude = [
        "**/test"
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
    };
  };
}
