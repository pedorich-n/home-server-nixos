_:
let
  backupFolder = "/mnt/store/grist/persist";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    grist = {
      paths = [
        backupFolder
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
    };
  };
}
