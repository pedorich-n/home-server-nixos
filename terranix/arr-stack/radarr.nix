{ trash-guides, lib, ... }:
let
  common = import ./_common.nix;

  # https://github.com/TRaSH-Guides/Guides/blob/master/docs/json/radarr/naming/radarr-naming.json
  naming = lib.importJSON "${trash-guides}/docs/json/radarr/naming/radarr-naming.json";
in
{
  resource = {
    # Schema https://registry.terraform.io/providers/devopsarr/radarr/2.3.1/docs/resources/root_folder
    radarr_root_folder.root = {
      path = "/data/media/movies";
    };

    # Schema https://registry.terraform.io/providers/devopsarr/radarr/2.3.1/docs/resources/naming
    # See https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/#jellyfin
    # Using Jellyfin TMDB recommendation
    radarr_naming.naming = {
      rename_movies = true;
      replace_illegal_characters = true;
      colon_replacement_format = "smart";
      standard_movie_format = naming.file."jellyfin-tmdb";
      movie_folder_format = naming.folder."jellyfin-tmdb";
    };

    # Schema https://registry.terraform.io/providers/devopsarr/radarr/2.3.1/docs/resources/download_client_sabnzbd
    radarr_download_client_sabnzbd.sabnzbd = common.sabnzbdDownloadClient // {
      movie_category = "movies";
    };
  };
}
