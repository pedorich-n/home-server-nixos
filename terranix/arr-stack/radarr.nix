let
  common = import ./_common.nix;
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
      standard_movie_format = "{Movie CleanTitle} {(Release Year)} [tmdbid-{TmdbId}] - {Edition Tags }{[Custom Formats]}{[Quality Full]}{[MediaInfo 3D]}{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[Mediainfo VideoCodec]}{-Release Group}";
      movie_folder_format = "{Movie CleanTitle} ({Release Year}) [tmdbid-{TmdbId}]";
    };

    # Schema https://registry.terraform.io/providers/devopsarr/radarr/2.3.1/docs/resources/download_client_sabnzbd
    radarr_download_client_sabnzbd.sabnzbd = common.sabnzbdDownloadClient // {
      movie_category = "movies";
    };
  };
}
