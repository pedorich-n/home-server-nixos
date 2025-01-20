{ lib, customLib, ... }:
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


  torrentIndexer = args: {
    enable = true;
    app_profile_id = tfRef "resource.prowlarr_sync_profile.automatic.id";
    protocol = "torrent";
    fields = [
      { name = "baseSettings.limitsUnit"; number_value = 0; } # 0 means Day, 1 means Hour
      { name = "torrentBaseSettings.preferMagnetUrl"; bool_value = false; }
    ] ++ (args.fields or [ ]);
  } // (builtins.removeAttrs args [ "fields" ]);
in
{
  locals = {
    secrets = {
      prowlarr_indexer_credentials = customLib.mkOnePasswordMapping "prowlarr_indexers";
      sonarr = customLib.mkOnePasswordMapping "sonarr";
      radarr = customLib.mkOnePasswordMapping "radarr";
      prowlarr = customLib.mkOnePasswordMapping "prowlarr";
      sabnzbd = customLib.mkOnePasswordMapping "sabnzbd";
    };
  };

  resource = {
    # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/indexer
    prowlarr_indexer = {
      #SECTION - Usenet
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
        priority = 40;
        fields = [
          { name = "baseUrl"; text_value = "https://nzbfinder.ws"; }
          { name = "vipExpiration"; text_value = ""; }
          { name = "baseSettings.queryLimit"; number_value = 15; }
          { name = "baseSettings.grabLimit"; number_value = 3; }
          { name = "baseSettings.limitsUnit"; number_value = 0; } # 0 means Day, 1 means Hour
        ];
      };
      #!SECTION - Usenet

      #SECTION - Torrent
      # torrentleech = torrentIndexer rec {
      #   name = "TorrentLeech";
      #   priority = 15;
      #   implementation = "Cardigann";
      #   config_contract = "CardigannSettings";
      #   fields = [
      #     { name = "baseUrl"; text_value = "https://www.torrentleech.org/"; }
      #     { name = "definitionFile"; text_value = "torrentleech"; }
      #     { name = "username"; text_value = tfRef ''local.secrets.prowlarr_indexer_credentials["${name}"].username''; }
      #     # Not marked as sensitive by the provider :(
      #     { name = "password"; text_value = tfRef ''local.secrets.prowlarr_indexer_credentials["${name}"].password''; }
      #   ];
      # };


      toloka = torrentIndexer rec {
        name = "Toloka";
        priority = 30;
        implementation = "Toloka";
        config_contract = "TolokaSettings";
        fields = [
          { name = "baseUrl"; text_value = "https://toloka.to/"; }
          { name = "stripCyrillicLetters"; bool_value = false; }
          { name = "freeleechOnly"; bool_value = false; }
          { name = "username"; text_value = tfRef ''local.secrets.prowlarr_indexer_credentials["${name}"].username''; }
          { name = "password"; sensitive_value = tfRef ''local.secrets.prowlarr_indexer_credentials["${name}"].password''; }
        ];
      };

      rutracker = torrentIndexer rec {
        name = "Rutracker";
        priority = 30;
        implementation = "RuTracker";
        config_contract = "RuTrackerSettings";
        fields = [
          { name = "baseUrl"; text_value = "https://rutracker.org/"; }
          { name = "russianLetters"; bool_value = false; }
          { name = "useMagnetLinks"; bool_value = false; }
          { name = "addRussianToTitle"; bool_value = false; }
          { name = "moveFirstTagsToEndOfReleaseTitle"; bool_value = false; }
          { name = "moveAllTagsToEndOfReleaseTitle"; bool_value = false; }
          { name = "username"; text_value = tfRef ''local.secrets.prowlarr_indexer_credentials["${name}"].username''; }
          { name = "password"; sensitive_value = tfRef ''local.secrets.prowlarr_indexer_credentials["${name}"].password''; }
        ];
      };

      #!SECTION - Torrent
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
