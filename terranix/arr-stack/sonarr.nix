{ trash-guides, lib, ... }:
let
  common = import ./_common.nix;

  # https://github.com/TRaSH-Guides/Guides/blob/master/docs/json/sonarr/naming/sonarr-naming.json
  naming = lib.importJSON "${trash-guides}/docs/json/sonarr/naming/sonarr-naming.json";

  # https://github.com/TRaSH-Guides/Guides/blob/master/docs/json/sonarr/quality-size/series.json
  qualityDefinitions = lib.importJSON "${trash-guides}/docs/json/sonarr/quality-size/series.json";
in
{
  locals = {
    trash_quality_definitions = qualityDefinitions.qualities;

    existing_definitions_map = "\${{for item in data.sonarr_quality_definitions.main.quality_definitions : item.title => item }}";

    mapped_definitions = ''''${
      [ 
        for quality in local.trash_quality_definitions: {
          title = quality.quality
          min_size = quality.min
          max_size = quality.max
          id = local.existing_definitions_map[quality.quality].id
        } if contains(keys(local.existing_definitions_map), quality.quality) 
      ]
    }'';
  };

  data = {
    sonarr_quality_definitions.main = { };
  };

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

      standard_episode_format = naming.episodes.standard.default;
      daily_episode_format = naming.episodes.daily.default;
      anime_episode_format = naming.episodes.anime.default;
      series_folder_format = naming.series."jellyfin-tvdb";
      season_folder_format = naming.season.default;
      specials_folder_format = "Specials";
    };

    # Schema https://registry.terraform.io/providers/devopsarr/sonarr/3.3.0/docs/resources/download_client_sabnzbd
    sonarr_download_client_sabnzbd .sabnzbd = common.sabnzbdDownloadClient // {
      tv_category = "tv";
    };
  };
}
