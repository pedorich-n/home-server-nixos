{ trash-guides, lib, ... }:
let
  inherit (lib) tfRef;

  common = import ./_common.nix { inherit lib; };

  # https://github.com/TRaSH-Guides/Guides/blob/master/docs/json/sonarr/naming/sonarr-naming.json
  naming = lib.importJSON "${trash-guides}/docs/json/sonarr/naming/sonarr-naming.json";

  # https://github.com/TRaSH-Guides/Guides/blob/master/docs/json/sonarr/quality-size/series.json
  qualityDefinitions = lib.importJSON "${trash-guides}/docs/json/sonarr/quality-size/series.json";
in
{
  locals = {
    sonarr_qd_trash = qualityDefinitions.qualities;

    sonarr_qd_existing = tfRef "{ for item in data.sonarr_quality_definitions.main.quality_definitions : item.title => item }";

    sonarr_qd_trash_mapped = tfRef ''{
      for quality in local.sonarr_qd_trash: quality.quality => {
        title = quality.quality
        min_size = quality.min
        max_size = quality.max
        preferred_size = quality.preferred
        id = local.sonarr_qd_existing[quality.quality].id
      } if contains(keys(local.sonarr_qd_existing), quality.quality) 
    }'';
  };

  data = {
    sonarr_quality_definitions.main = { };
  };

  resource = {
    # Schema https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/data-sources/root_folder
    sonarr_root_folder.root = {
      path = "/data/media/tv";
    };

    # Schema https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/data-sources/naming
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

    # Schema https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/resources/download_client_sabnzbd
    sonarr_download_client_sabnzbd .sabnzbd = common.sabnzbdDownloadClient // {
      tv_category = "tv";
    };

    # Schema https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/resources/quality_definition
    sonarr_quality_definition.trash = {
      for_each = tfRef "local.sonarr_qd_trash_mapped";
      title = tfRef "each.value.title";
      id = tfRef "each.value.id";
      min_size = tfRef "each.value.min_size";
      max_size = tfRef "each.value.max_size";
      preferred_size = tfRef "each.value.preferred_size";
    };
  };
}
