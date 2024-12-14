let
  common = import ./_common.nix;
in
{
  resource = {
    # Schema https://registry.terraform.io/providers/devopsarr/sonarr/latest/docs/data-sources/root_folder
    sonarr_root_folder.root = {
      path = "/data/media/tv";
    };

    # Schema https://registry.terraform.io/providers/devopsarr/sonarr/3.3.0/docs/data-sources/naming
    # See https://trash-guides.info/Sonarr/Sonarr-recommended-naming-scheme/
    # Using Jellyfin TVDB recommendation
    sonarr_naming.naming = {
      rename_episodes = true;
      replace_illegal_characters = true;
      colon_replacement_format = 4; # Smart
      multi_episode_style = 5; # Prefixed Range

      standard_episode_format = "{Series TitleYear} - S{season:00}E{episode:00} - {Episode CleanTitle} [{Custom Formats }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[MediaInfo VideoCodec]}{-Release Group}";
      daily_episode_format = "{Series TitleYear} - {Air-Date} - {Episode CleanTitle} [{Custom Formats }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[MediaInfo VideoCodec]}{-Release Group}";
      anime_episode_format = "{Series TitleYear} - S{season:00}E{episode:00} - {absolute:000} - {Episode CleanTitle} [{Custom Formats }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}[{MediaInfo VideoBitDepth}bit]{[MediaInfo VideoCodec]}[{Mediainfo AudioCodec} { Mediainfo AudioChannels}]{MediaInfo AudioLanguages}{-Release Group}";
      series_folder_format = "{Series TitleYear} [tvdbid-{TvdbId}]";
      season_folder_format = "Season {season:00}";
      specials_folder_format = "Specials";
    };

    # Schema https://registry.terraform.io/providers/devopsarr/sonarr/3.3.0/docs/resources/download_client_sabnzbd
    sonarr_download_client_sabnzbd .sabnzbd = common.sabnzbdDownloadClient // {
      tv_category = "tv";
    };
  };
}
