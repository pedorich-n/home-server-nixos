{ trash-guides, lib, ... }:
let
  inherit (lib) tfRef;

  common = import ./_common.nix { inherit lib; };

  # https://github.com/TRaSH-Guides/Guides/blob/master/docs/json/sonarr/naming/sonarr-naming.json
  naming = lib.importJSON "${trash-guides}/docs/json/sonarr/naming/sonarr-naming.json";

  # https://github.com/TRaSH-Guides/Guides/blob/master/docs/json/sonarr/quality-size/series.json
  qualityDefinitions = lib.importJSON "${trash-guides}/docs/json/sonarr/quality-size/series.json";

  # https://github.com/TRaSH-Guides/Guides/blob/master/docs/json/sonarr/quality-profiles/web-1080p.json
  qualityProfile = lib.importJSON "${trash-guides}/docs/json/sonarr/quality-profiles/web-1080p.json";

  # https://github.com/TRaSH-Guides/Guides/blob/master/docs/json/sonarr/cf
  customFormatsMapped =
    let
      files = lib.filesystem.listFilesRecursive "${trash-guides}/docs/json/sonarr/cf";

      mkEntry = file:
        let
          json = lib.importJSON file;
        in
        {
          ${json.trash_id} = json;
        };
    in
    lib.foldl' (acc: file: acc // (mkEntry file)) { } files;

  # A map where key is the CF name and value - CF definition
  customFormatsForQualityProfile = lib.mapAttrs (_: trash_id: customFormatsMapped.${trash_id}) qualityProfile.formatItems;
in
{
  locals = {
    sonarr_quality_definitions_trash = qualityDefinitions.qualities;

    # A map where key is the Quality Definition name, and value is the Quality Definition
    sonarr_quality_definition_existing = tfRef "{ for item in data.sonarr_quality_definitions.main.quality_definitions : item.title => item }";

    sonarr_quality_definition_trash_mapped = tfRef ''{
      for quality in local.sonarr_quality_definitions_trash: quality.quality => {
        title = quality.quality
        min_size = quality.min
        max_size = quality.max
        preferred_size = quality.preferred
        id = local.sonarr_quality_definition_existing[quality.quality].id
      } if contains(keys(local.sonarr_quality_definition_existing), quality.quality) 
    }'';

    sonarr_custom_formats_mapped = customFormatsForQualityProfile;
  };

  data = {
    sonarr_quality_definitions.main = { };
  };

  resource = {
    # https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/data-sources/root_folder
    sonarr_root_folder.root = {
      path = "/data/media/tv";
    };

    # https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/data-sources/naming
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

    # https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/resources/download_client_sabnzbd
    sonarr_download_client_sabnzbd .sabnzbd = common.sabnzbdDownloadClient // {
      tv_category = "tv";
    };

    # https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/resources/download_client_qbittorrent
    sonarr_download_client_qbittorrent.qbittorrent = common.qBittorrentDownloadClient // {
      tv_category = "tv";
    };

    # https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/resources/quality_definition
    sonarr_quality_definition.trash = {
      for_each = tfRef "local.sonarr_quality_definition_trash_mapped";
      title = tfRef "each.value.title";
      id = tfRef "each.value.id";
      min_size = tfRef "each.value.min_size";
      max_size = tfRef "each.value.max_size";
      preferred_size = tfRef "each.value.preferred_size";
    };

    # https://registry.terraform.io/providers/devopsarr/sonarr/3.4.0/docs/resources/custom_format
    sonarr_custom_format.trash = {
      for_each = tfRef "local.sonarr_custom_formats_mapped";
      name = tfRef "each.key";
      include_custom_format_when_renaming = tfRef "each.value.includeCustomFormatWhenRenaming";
      specifications = tfRef ''[
        for spec in each.value.specifications: {
          name = spec.name,
          implementation = spec.implementation,
          negate = spec.negate,
          required = spec.required,
          value = spec.fields.value
        }
      ]'';
    };
  };
}
