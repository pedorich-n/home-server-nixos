{ lib, ... }:
let
  inherit (lib) tfRef;

  common = import ./_common.nix { inherit lib; };

  prowlarInternalUrl = "http://prowlarr:9696";

  nzbIndexer = args: {
    enable = true;
    implementation = "Newznab";
    config_contract = "NewznabSettings";
    protocol = "usenet";
    fields = [
      { name = "apiPath"; text_value = "/api"; }
      { name = "apiKey"; sensitive_value = tfRef ''local.secrets.prowlarr_indexer_credentials["${args.name}"].api_key''; }
    ] ++ (args.fields or [ ]);
  } // (builtins.removeAttrs args [ "fields" ]);

  mkOnePasswordMapping = item: tfRef ''{ 
      for section in data.onepassword_item.${item}.section: section.label => {
        for field in section.field: field.label => field.value
      } 
    }'';
in
{
  locals = {
    secrets = {
      prowlarr_indexer_credentials = mkOnePasswordMapping "prowlarr_indexers";
      sonarr = mkOnePasswordMapping "sonarr";
      radarr = mkOnePasswordMapping "radarr";
      prowlarr = mkOnePasswordMapping "prowlarr";
      sabnzbd = mkOnePasswordMapping "sabnzbd";
    };
  };

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

    # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/download_client_sabnzbd
    prowlarr_download_client_sabnzbd.sabnzbd = common.sabnzbdDownloadClient // {
      category = "prowlarr";
    };

    # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/download_client_qbittorrent
    prowlarr_download_client_qbittorrent.qbittorrent = common.qBittorrentDownloadClient // {
      category = "prowlarr";
    };

    # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/application_radarr
    prowlarr_application_radarr.radarr = {
      name = "Radarr";
      sync_level = "fullSync";
      base_url = "http://radarr:7878";
      prowlarr_url = prowlarInternalUrl;
      api_key = tfRef ''local.secrets.radarr["API"]["key"]'';
    };

    # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/application_sonarr
    prowlarr_application_sonarr.sonarr = {
      name = "Sonarr";
      sync_level = "fullSync";
      base_url = "http://sonarr:8989";
      prowlarr_url = prowlarInternalUrl;
      api_key = tfRef ''local.secrets.sonarr["API"]["key"]'';
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
