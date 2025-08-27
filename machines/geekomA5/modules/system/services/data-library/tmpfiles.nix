{
  lib,
  tmpfilesLib,
  ...
}:
let
  storeRoot = "/mnt/store/data-library";
  externalRoot = "/mnt/external/data-library";

  foldersToCreate =
    (lib.map (folder: "${storeRoot}/${folder}") [
      "audiobookshelf/config"
      "audiobookshelf/metadata"

      "jellyfin/cache"
      "jellyfin/config"

      "prowlarr/config"

      "qbittorrent/config"

      "radarr/config"

      "sabnzbd/config"

      "sonarr/config"

      "recyclarr/config"
    ])
    ++ (lib.map (folder: "${externalRoot}/${folder}") [
      "downloads/usenet/incomplete"
      "downloads/usenet/complete/tv"
      "downloads/usenet/complete/movies"
      "downloads/usenet/complete/audiobooks"
      "downloads/usenet/complete/prowlarr"

      "downloads/torrent/temporary"
      "downloads/torrent/incomplete"
      "downloads/torrent/complete/tv"
      "downloads/torrent/complete/movies"
      "downloads/torrent/complete/audiobooks"
      "downloads/torrent/complete/prowlarr"

      "media/tv"
      "media/movies"
      "media/music-videos"
      "media/audiobooks"

      "share"
    ]);

  foldersToSetPermissions = [
    storeRoot
    externalRoot
  ];

  extraCreateRules = {
    "${storeRoot}/recyclarr/config/configs" = {
      "C+" = tmpfilesLib.mkDefaultTmpDirectory "${./recyclarr}";
    };
  };
in
{
  systemd.tmpfiles.settings = {
    "90-data-library-create" = lib.mkMerge [
      (tmpfilesLib.createFoldersUsingDefaultMediaRule foldersToCreate)
      extraCreateRules
    ];
    "91-data-library-set" = tmpfilesLib.setPermissionsUsingDefaultMediaRule foldersToSetPermissions;
  };
}
