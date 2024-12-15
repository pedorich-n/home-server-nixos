{ trash-guides, lib, ... }:
let
  common = import ./_common.nix;

  # https://github.com/TRaSH-Guides/Guides/blob/master/docs/json/radarr/naming/radarr-naming.json
  naming = lib.importJSON "${trash-guides}/docs/json/radarr/naming/radarr-naming.json";

  # https://github.com/TRaSH-Guides/Guides/blob/master/docs/json/radarr/quality-size/movie.json
  qualityDefinitions = lib.importJSON "${trash-guides}/docs/json/radarr/quality-size/movie.json";
in
{
  locals = {
    radarr_qd_trash = qualityDefinitions.qualities;

    radarr_qd_existing = "\${{for item in data.radarr_quality_definitions.main.quality_definitions : item.title => item }}";

    radarr_qd_trash_mapped = ''''${
      {
        for quality in local.radarr_qd_trash: quality.quality => {
          title = quality.quality
          min_size = quality.min
          max_size = quality.max
          preferred_size = quality.preferred
          id = local.radarr_qd_existing[quality.quality].id
        } if contains(keys(local.radarr_qd_existing), quality.quality) 
      }
    }'';
  };

  data = {
    radarr_quality_definitions.main = { };
  };

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

    # Schema https://registry.terraform.io/providers/devopsarr/radarr/2.3.1/docs/resources/quality_definition
    radarr_quality_definition.trash = {
      for_each = "\${local.radarr_qd_trash_mapped}";
      title = "\${each.value.title}";
      id = "\${each.value.id}";
      min_size = "\${each.value.min_size}";
      max_size = "\${each.value.max_size}";
      preferred_size = "\${each.value.preferred_size}";
    };
  };
}
