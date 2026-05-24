let
  backupRoot = "/mnt/store/trek";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    trek = {
      paths = [
        "${backupRoot}/data/travel.db"
        "${backupRoot}/uploads"
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
    };
  };
}
