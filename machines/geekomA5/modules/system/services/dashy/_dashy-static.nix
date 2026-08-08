{
  dashy-ui,
  lib,
  autheliaLib,
  networkingLib,
  ...
}:

let
  capitalize =
    word:
    let
      firstChar = lib.substring 0 1 word;
      restOfWord = lib.substring 1 (-1) word;
      upperFirstChar = lib.strings.toUpper firstChar;
    in
    "${upperFirstChar}${restOfWord}";

  mkEntry =
    {
      slug,
      title ? capitalize slug,
      iconName ? slug,
      icon ? "sh-${iconName}", # Fetches icons from https://selfh.st/icons/
      args ? { },
    }:
    {
      inherit title icon;
      url = networkingLib.mkLocalUrl slug;
      target = "newtab";
    }
    // args;

  # LINK - https://dashy.to/docs/configuring/
  dashySettings = {
    pageInfo = {
      title = "HomeLab";
    };

    appConfig = {
      disableContextMenu = true;

      layout = "horizontal";
      iconSize = "large";
      theme = "Cherry-Blossom";

      preventWriteToDisk = true;
      disableUpdateChecks = true;

      hideComponents = {
        hideHeading = true;
        hideSearch = true;
        hideNav = true;
        hideFooter = true;
      };

      auth = {
        enableOidc = true;
        enableGuestAccess = true;
        oidc = {
          clientId = "dashy";
          endpoint = autheliaLib.issuerUrl;
          scope = "openid profile email groups";
          adminGroup = autheliaLib.groups.Admins;
        };
      };
    };

    sections = [
      {
        name = "Media";
        icon = "mdi-multimedia";
        items = [
          (mkEntry {
            slug = "jellyfin";
          })
          (mkEntry {
            slug = "audiobookshelf";
          })
          (mkEntry {
            slug = "immich";
          })
          (mkEntry {
            slug = "navidrome";
          })
          (mkEntry {
            slug = "maloja";
          })
          (mkEntry {
            slug = "koito";
          })
        ];
      }
      {
        name = "Tools";
        icon = "mdi-cogs";
        items = [
          (mkEntry {
            slug = "chat";
            title = "LibreChat";
            iconName = "librechat";
          })
          (mkEntry {
            slug = "trek";
            title = "TREK";
            iconName = "trek-light";
          })
          (mkEntry {
            slug = "airtrail";
            title = "AirTrail";
          })
          (mkEntry {
            slug = "copyparty";
          })
          (mkEntry {
            slug = "git";
            title = "Forgejo";
            iconName = "forgejo";
          })
          (mkEntry {
            slug = "gitea-mirror";
            title = "Gitea Mirror";
            icon = "hl-gitea-mirror"; # Icon from https://dashboardicons.com/icons/gitea-mirror, as selfh.st one is wrong
            args = {
              displayData.showForGroups = [ autheliaLib.groups.Admins ];
            };
          })
          (mkEntry {
            slug = "searxng";
            title = "SearXNG";
          })
        ];
      }
      {
        name = "Home Automation";
        icon = "mdi-home-automation";
        items = [
          (mkEntry {
            slug = "homeassistant";
            title = "Home Assistant";
            iconName = "home-assistant";
          })
          (mkEntry {
            slug = "zigbee2mqtt";
            title = "Zigbee2MQTT";
          })
          (mkEntry {
            slug = "n8n";
            title = "n8n";
            args = {
              displayData.showForGroups = [ autheliaLib.groups.Admins ];
            };
          })
          (mkEntry {
            slug = "motioneye";
            title = "MotionEye";
            args = {
              displayData.showForGroups = [ autheliaLib.groups.Admins ];
            };
          })
        ];
      }
      {
        name = "Office";
        icon = "mdi-file-document-multiple";
        items = [
          (mkEntry {
            slug = "paperless";
            iconName = "paperless-ngx";
          })
          (mkEntry {
            slug = "bentopdf";
            title = "BentoPDF";
          })
          (mkEntry {
            slug = "grist";
          })
        ];
      }
      {
        name = "Media Management";
        icon = "mdi-movie-open-settings";
        displayData.showForGroups = [ autheliaLib.groups.Admins ];
        items = [
          (mkEntry {
            slug = "sonarr";
          })
          (mkEntry {
            slug = "radarr";
          })
          (mkEntry {
            slug = "lidarr";
          })
          (mkEntry {
            slug = "prowlarr";
          })
          (mkEntry {
            slug = "shelfmark";
          })
          (mkEntry {
            slug = "qbittorrent";
            title = "qBittorrent";
          })
          (mkEntry {
            slug = "sabnzbd";
            title = "SABnzbd";
          })
          (mkEntry {
            slug = "multiscrobbler";
            title = "MultiScrobbler";
            iconName = "multi-scrobbler";
          })
          (mkEntry {
            slug = "mousehole";
            title = "Mousehole";
            icon = "https://raw.githubusercontent.com/t-mart/mousehole/59f2dc091595e6d281215845a4cd18ee92752035/docs/images/logo/logo.png";
          })
        ];
      }
      {
        name = "Server Management";
        icon = "mdi-server";
        displayData.showForGroups = [ autheliaLib.groups.Admins ];
        items = [
          (mkEntry {
            slug = "netdata";
          })
          (mkEntry {
            slug = "olivetin";
          })
          (mkEntry {
            slug = "lldap";
            title = "LLDAP";
            iconName = "lldap-light";
          })
          (mkEntry {
            slug = "authelia";
          })
        ];
      }
    ];
  };

in
dashy-ui.override { settings = dashySettings; }
