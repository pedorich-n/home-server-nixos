{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    audiobookshelf = {
      paths = [
        "/mnt/store/data-library/audiobookshelf/config/absdatabase.sqlite"
        "/mnt/store/data-library/audiobookshelf/metadata/authors"
        "/mnt/store/data-library/audiobookshelf/metadata/items"
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
    };
  };
}
