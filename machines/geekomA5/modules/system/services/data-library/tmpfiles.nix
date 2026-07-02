{
  lib,
  tmpfilesLib,
  ...
}:
let
  storeRoot = "/mnt/store/data-library";
  # externalRoot = "/mnt/external/data-library";

  foldersToCreate = lib.map (folder: "${storeRoot}/${folder}") [
    "audiobookshelf/config"
    "audiobookshelf/metadata"

    "prowlarr/config"

    "mamapi/data"
    "mousehole"

    "qbittorrent/config"

    "shelfmark/config"
  ];

  # foldersToCreateExternal = lib.map (folder: "${externalRoot}/${folder}") [
  #   "downloads/usenet/incomplete"
  #   "downloads/usenet/complete/tv"
  #   "downloads/usenet/complete/movies"
  #   "downloads/usenet/complete/audiobooks"
  #   "downloads/usenet/complete/prowlarr"

  #   "downloads/torrent/incomplete"
  #   "downloads/torrent/complete/tv"
  #   "downloads/torrent/complete/movies"
  #   "downloads/torrent/complete/audiobooks"
  #   "downloads/torrent/complete/prowlarr"
  #   "downloads/torrent/complete/others"

  #   "media/tv"
  #   "media/movies"
  #   "media/music-videos"
  #   "media/audiobooks"

  #   "share"
  # ];

  foldersToSetPermissions = [
    storeRoot
  ];

  # foldersToSetPermissionsExternal = [
  #   externalRoot
  # ];

in
{
  systemd.tmpfiles.settings = {
    "90-data-library-create" = lib.mkMerge [
      (tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate)
      # (tmpfilesLib.createFoldersUsingDefaultMediaRule foldersToCreateExternal)
    ];
    "91-data-library-set" = lib.mkMerge [
      (tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions)
      # (tmpfilesLib.setPermissionsUsingDefaultMediaRule foldersToSetPermissionsExternal)
    ];
  };
}
