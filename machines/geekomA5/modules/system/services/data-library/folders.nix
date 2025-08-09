{ lib, tmpfilesLib, ... }:
let
  storeRoot = "/mnt/store/data-library";
  externalRoot = "/mnt/external/data-library";

  foldersToCreate =
    (lib.map (folder: "${storeRoot}/${folder}") [
      "audiobookshelf"
      "audiobookshelf/config"
      "audiobookshelf/metadata"

      "jellyfin"
      "jellyfin/cache"
      "jellyfin/config"

      "prowlarr"
      "prowlarr/config"

      "qbittorrent"
      "qbittorrent/config"

      "radarr"
      "radarr/config"

      "sabnzbd"
      "sabnzbd/config"

      "sonarr"
      "sonarr/config"
    ])
    ++ (lib.map (folder: "${externalRoot}/${folder}") [
      "downloads/usenet"
      "downloads/usenet/incomplete"
      "downloads/usenet/complete"
      "downloads/usenet/complete/tv"
      "downloads/usenet/complete/movies"
      "downloads/usenet/complete/audiobooks"
      "downloads/usenet/complete/prowlarr"

      "downloads/torrent"
      "downloads/torrent/temporary"
      "downloads/torrent/incomplete"
      "downloads/torrent/complete"
      "downloads/torrent/complete/tv"
      "downloads/torrent/complete/movies"
      "downloads/torrent/complete/audiobooks"
      "downloads/torrent/complete/prowlarr"

      "media"
      "media/tv"
      "media/movies"
      "media/audiobooks"
    ]);

  foldersToSetPermissions = [
    storeRoot
    externalRoot
  ];
in
{
  systemd.tmpfiles.settings = {
    "90-data-library-create" = tmpfilesLib.createFoldersUsingDefaultRule foldersToCreate;
    "91-data-library-set" = tmpfilesLib.setPermissionsUsingDefaultRule foldersToSetPermissions;
  };
}
