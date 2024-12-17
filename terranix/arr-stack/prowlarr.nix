{ lib, ... }:
let
  inherit (lib) tfRef;

  prowlarInternalUrl = "http://prowlarr:9696";

  nzbIndexer = args: {
    enable = true;
    implementation = "Newznab";
    config_contract = "NewznabSettings";
    protocol = "usenet";
    fields = [
      { name = "apiPath"; text_value = "/api"; }
      { name = "apiKey"; sensitive_value = tfRef ''var.indexers["${args.name}"]''; }
    ] ++ (args.fields or [ ]);
  } // (builtins.removeAttrs args [ "fields" ]);
in
{
  resource = {
    # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/indexer
    prowlarr_indexer = {
      nzbgeek = nzbIndexer {
        app_profile_id = tfRef "resource.prowlarr_sync_profile.automatic.id";
        name = "NZBGeek";
        priority = 20;
        fields = [
          { name = "baseUrl"; text_value = "https://api.nzbgeek.info"; }
          { name = "vipExpiration"; text_value = "2025-06-13"; }
          { name = "baseSettings.limitsUnit"; number_value = 0; } # 0 means Day, 1 means Hour
        ];
      };

      nzbfinder = nzbIndexer {
        app_profile_id = tfRef "resource.prowlarr_sync_profile.interactive.id";
        name = "NZBFinder";
        priority = 35;
        fields = [
          { name = "baseUrl"; text_value = "https://nzbfinder.ws"; }
          { name = "vipExpiration"; text_value = ""; }
          { name = "baseSettings.queryLimit"; number_value = 15; }
          { name = "baseSettings.grabLimit"; number_value = 3; }
          { name = "baseSettings.limitsUnit"; number_value = 0; } # 0 means Day, 1 means Hour
        ];
      };
    };

    # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/application_radarr
    prowlarr_application_radarr.radarr = {
      name = "Radarr";
      sync_level = "fullSync";
      base_url = "http://radarr:7878";
      prowlarr_url = prowlarInternalUrl;
      api_key = tfRef ''var.arrs["radarr"]'';
    };

    # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/application_sonarr
    prowlarr_application_sonarr.sonarr = {
      name = "Sonarr";
      sync_level = "fullSync";
      base_url = "http://sonarr:8989";
      prowlarr_url = prowlarInternalUrl;
      api_key = tfRef ''var.arrs["sonarr"]'';
    };

    # Schema https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/sync_profile
    prowlarr_sync_profile = {
      # As recommended by https://trash-guides.info/Prowlarr/prowlarr-setup-limited-api/
      automatic = {
        name = "Automatic";
        enable_rss = false;
        enable_automatic_search = true;
        enable_interactive_search = true;
        minimum_seeders = 20;
      };

      interactive = {
        name = "Interactive";
        enable_rss = false;
        enable_automatic_search = false;
        enable_interactive_search = true;
        minimum_seeders = 20;
      };
    };
  };
}
