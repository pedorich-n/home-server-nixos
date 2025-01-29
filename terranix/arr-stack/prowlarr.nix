{ lib, ... }:
let
  inherit (lib) tfRef;

  common = import ./_common.nix { inherit lib; };

  prowlarrInternalUrl = "http://prowlarr:9696";

  nzbIndexer = args: {
    enable = true;
    implementation = "Newznab";
    config_contract = "NewznabSettings";
    protocol = "usenet";
    fields = [
      { name = "apiPath"; text_value = "/api"; }
      { name = "apiKey"; sensitive_value = tfRef "local.secrets.prowlarr_indexers.${args.name}.api_key"; }
    ] ++ (args.fields or [ ]);
  } // (builtins.removeAttrs args [ "fields" ]);


  torrentIndexer = args: {
    enable = true;
    app_profile_id = tfRef "data.prowlarr_sync_profile.standard.id";
    implementation = "Cardigann";
    config_contract = "CardigannSettings";
    protocol = "torrent";
    fields = [
      { name = "baseSettings.limitsUnit"; number_value = 0; } # 0 means Day, 1 means Hour
      { name = "torrentBaseSettings.preferMagnetUrl"; bool_value = false; }
    ] ++ (args.fields or [ ]);
  } // (builtins.removeAttrs args [ "fields" ]);
in
{
  data = {
    prowlarr_sync_profile.standard = {
      name = "Standard";
    };
  };

  resource = {
    # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/indexer
    prowlarr_indexer = {
      #SECTION - Usenet
      nzbgeek = nzbIndexer {
        app_profile_id = tfRef "data.prowlarr_sync_profile.standard.id";
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
      torrentleech = torrentIndexer rec {
        name = "TorrentLeech";
        priority = 10;
        fields = [
          { name = "baseUrl"; text_value = "https://www.torrentleech.org/"; }
          { name = "definitionFile"; text_value = "torrentleech"; }
          { name = "exclude_archives"; bool_value = false; }
          { name = "exclude_scene"; bool_value = false; }
          { name = "freeleech"; bool_value = false; }
          { name = "sort"; number_value = 0; } # Sort by Created
          { name = "type"; number_value = 1; } # Sort desc
          { name = "username"; text_value = tfRef "local.secrets.prowlarr_indexers.${name}.username"; }
          { name = "password"; text_value = tfRef "local.secrets.prowlarr_indexers.${name}.password"; }
        ];
      };

      milkie = torrentIndexer rec {
        name = "Milkie";
        priority = 15;
        fields = [
          { name = "baseUrl"; text_value = "https://milkie.cc/"; }
          { name = "definitionFile"; text_value = "milkie"; }
          { name = "apikey"; text_value = tfRef "local.secrets.prowlarr_indexers.${name}.api_key"; }
        ];
      };

      therarbg = torrentIndexer {
        name = "TheRARBG";
        app_profile_id = tfRef "resource.prowlarr_sync_profile.automatic.id";
        priority = 25;
        fields = [
          { name = "baseUrl"; text_value = "https://therarbg.to/"; }
          { name = "definitionFile"; text_value = "therarbg"; }
          { name = "sort"; number_value = 0; } # Created desc
        ];
      };

      toloka = torrentIndexer rec {
        name = "Toloka";
        priority = 30;
        implementation = "Toloka";
        config_contract = "TolokaSettings";
        fields = [
          { name = "baseUrl"; text_value = "https://toloka.to/"; }
          { name = "stripCyrillicLetters"; bool_value = false; }
          { name = "freeleechOnly"; bool_value = false; }
          { name = "username"; text_value = tfRef "local.secrets.prowlarr_indexers.${name}.username"; }
          { name = "password"; sensitive_value = tfRef "local.secrets.prowlarr_indexers.${name}.password"; }
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
          { name = "username"; text_value = tfRef "local.secrets.prowlarr_indexers.${name}.username"; }
          { name = "password"; sensitive_value = tfRef "local.secrets.prowlarr_indexers.${name}.password"; }
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
      prowlarr_url = prowlarrInternalUrl;
      api_key = tfRef "local.secrets.radarr.API.key";
    };

    # https://registry.terraform.io/providers/devopsarr/prowlarr/2.4.3/docs/resources/application_sonarr
    prowlarr_application_sonarr.sonarr = {
      name = "Sonarr";
      sync_level = "fullSync";
      base_url = "http://sonarr:8989";
      prowlarr_url = prowlarrInternalUrl;
      api_key = tfRef "local.secrets.sonarr.API.key";
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
