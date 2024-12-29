{ config, lib, ... }:
let
  defaultRules = {
    user = config.users.users.user.name;
    group = config.users.users.user.group;
    mode = "0755";
  };

  mkDirectoryRules = {
    "d" = defaultRules; # Create a directory
    "z" = defaultRules; # Set mode/permissions to a directory, in case it already exists
  };

  folders = lib.map (folder: "/mnt/external/data-library/${folder}") [
    "downloads/usenet"
    "downloads/usenet/incomplete"
    "downloads/usenet/complete"
    "downloads/usenet/complete/tv"
    "downloads/usenet/complete/movies"
    "downloads/usenet/complete/audiobooks"
    "downloads/usenet/complete/prowlarr"

    "downloads/torrent"
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
  ];
in
{
  systemd.tmpfiles.settings."90-data-library" = lib.foldl' (acc: folder: acc // { ${folder} = mkDirectoryRules; }) { } folders;
}
