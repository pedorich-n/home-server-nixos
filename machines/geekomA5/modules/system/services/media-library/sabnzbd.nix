{
  config,
  pkgs-unstable,
  networkingLib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.sabnzbd;

  usensetRoot = "/mnt/external/data-library/downloads/usenet";
in
{

  custom = {
    networking.ports.tcp.sabnzbd = {
      port = 30900;
      openFirewall = false;
    };

    services.caddy.hosts.sabnzbd = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
      auth = "authelia";
      authBypassPaths = [ "/api*" ];
    };
  };

  services.sabnzbd = {
    enable = true;
    package = pkgs-unstable.sabnzbd;
    group = "media";

    allowConfigWrite = true;
    secretFiles = [
      config.sops.templates."media-library/sabnzbd/secrets.ini".path
    ];
    settings = {
      misc = {
        host = "127.0.0.1";
        port = portsCfg.port;
        inet_exposure = "none";
        host_whitelist = networkingLib.mkDomain "sabnzbd";
        direct_unpack = true;

        download_dir = "${usensetRoot}/incomplete";
        complete_dir = "${usensetRoot}/complete";
        permissions = "775";
      };
      categories = {
        "*" = {
          name = "*";
          priority = 0;
          order = 0;
          dir = "";
        };
        movies = {
          name = "movies";
          priority = -100;
          order = 1;
          dir = "movies";
        };
        tv = {
          name = "tv";
          priority = -100;
          order = 2;
          dir = "tv";
        };
        audiobooks = {
          name = "audiobooks";
          priority = -100;
          order = 3;
          dir = "audiobooks";
        };
        prowlarr = {
          name = "prowlarr";
          priority = -100;
          order = 4;
          dir = "prowlarr";
        };
      };

      servers = {
        blocknews = {
          enable = true;
          name = "blocknews";
          displayname = "Blocknews";
          host = "asnews.blocknews.net";
          port = 563;
          ssl = true;
          connections = 65;
          quota = "2500G";
          priority = 10;
        };

        thundernews = {
          enable = true;
          name = "thundernews";
          displayname = "Thundernews";
          host = "secure.us.thundernews.com";
          port = 563;
          ssl = true;
          connections = 50;
          quota = "470G";
          priority = 50;
        };
      };
    };
  };
}
