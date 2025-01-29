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
  # enabledQualityGroups = lib.filter (item: item.allowed) qualityProfile.items;
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

    sonarr_quality_groups_existing = tfRef ''toset(flatten([for qp in data.sonarr_quality_profiles.existing.quality_profiles: qp.quality_groups ]))'';
  };

  data = {
    sonarr_quality_definitions.main = { };

    sonarr_quality_profiles.existing = { };

    sonarr_quality_profile.existing1080p = {
      name = "HD-1080p";
    };
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

    #TODO: come back to this one day, when I have the patience to deal with weird API
    #SECTION - quality profile
    # sonarr_quality_profile.trash1080p =
    #   let
    #     mkTfFormatItem = name: item: {
    #       inherit name;
    #       format = tfRef ''sonarr_custom_format.trash["${name}"].id'';
    #       score = item.trash_scores.default;
    #     };

    #     mkTfQualityGroup = group: {
    #       inherit (group) name;
    #       id = tfRef ''one([for group in local.sonarr_quality_groups_existing : group if group.name == "${group.name}"]).id'';
    #       qualities = lib.map (quality: tfRef ''local.sonarr_quality_definition_existing["${quality}"]'') group.items;
    #     };
    #   in
    #   {
    #     name = qualityProfile.name;
    #     cutoff_format_score = qualityProfile.cutoffFormatScore;
    #     min_format_score = qualityProfile.minFormatScore;
    #     min_upgrade_format_score = qualityProfile.minUpgradeFormatScore;
    #     upgrade_allowed = qualityProfile.upgradeAllowed;
    #     cutoff = tfRef ''one([for group in local.sonarr_quality_groups_existing : group if group.name == "${qualityProfile.cutoff}"]).id'';

    #     format_items = lib.mapAttrsToList mkTfFormatItem customFormatsForQualityProfile;
    #     quality_groups = lib.map mkTfQualityGroup enabledQualityGroups;
    #   };

    # sonarr_quality_profile.updated1080p =
    #   let
    #     mkTfFormatItem = name: item: {
    #       inherit name;
    #       # format = tfRef ''sonarr_custom_format.trash["${name}"].id'';
    #       score = item.trash_scores.default;
    #     };
    #   in
    #   {
    #     name = "HD-1080p - 2";
    #     cutoff_format_score = tfRef "data.sonarr_quality_profile.existing1080p.cutoff_format_score";
    #     cutoff = tfRef "data.sonarr_quality_profile.existing1080p.cutoff";
    #     min_format_score = tfRef "data.sonarr_quality_profile.existing1080p.min_format_score";
    #     min_upgrade_format_score = tfRef "data.sonarr_quality_profile.existing1080p.min_upgrade_format_score";
    #     upgrade_allowed = tfRef "data.sonarr_quality_profile.existing1080p.upgrade_allowed";

    #     quality_groups = tfRef "data.sonarr_quality_profile.existing1080p.quality_groups";
    #     format_items = lib.mapAttrsToList mkTfFormatItem customFormatsForQualityProfile;
    #   };
    #!SECTION - quality profile
  };
}
