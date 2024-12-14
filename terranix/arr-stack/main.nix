let
  prowlarInternalUrl = "http://prowlarr:9696";
in
{
  resource = {
    "prowlarr_indexer" = {
      "nzbgeek" = rec {
        app_profile_id = 1; # No idea what this means, but it's `1` for all the indexers I have
        enable = true;
        name = "NZBGeek";
        implementation = "Newznab";
        config_contract = "NewznabSettings";
        protocol = "usenet";
        priority = 20;
        fields = [
          { name = "baseUrl"; text_value = "https://api.nzbgeek.info"; }
          { name = "apiPath"; text_value = "/api"; }
          { name = "apiKey"; sensitive_value = "\${var.indexers[\"${name}\"]}"; }
          { name = "vipExpiration"; text_value = "2025-06-13"; }
          { name = "baseSettings.limitsUnit"; number_value = 0; }
        ];
      };
    };

    "prowlarr_application_radarr"."radarr" = {
      name = "Radarr";
      sync_level = "fullSync";
      base_url = "http://radarr:7878";
      prowlarr_url = prowlarInternalUrl;
      api_key = "\${var.radarr_api_key}";
    };

    "prowlarr_application_sonarr"."sonarr" = {
      name = "Sonarr";
      sync_level = "fullSync";
      base_url = "http://sonarr:8989";
      prowlarr_url = prowlarInternalUrl;
      api_key = "\${var.sonarr_api_key}";
    };
  };
}
