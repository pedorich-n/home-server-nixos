{
  pkgs,
  lib,
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
      iconLink ? "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/${iconName}.png",
    }:
    {
      inherit title;
      url = networkingLib.mkUrl slug;
      icon = iconLink;
      target = "newtab";
    };

  # LINK - https://dashy.to/docs/configuring/
  dashySettings = {
    pageInfo = {
      title = "Dashy";
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
        oidc = {
          clientId = "dashy";
          endpoint = networkingLib.mkUrl "authelia";
          scope = "openid profile email groups";
          adminGroup = "Admins";
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
            slug = "ente";
            iconLink = "https://ente.io/assets/ente-photos-icon-transparent.png";
          })
          (mkEntry {
            slug = "copyparty";
          })
          (mkEntry {
            slug = "maloja";
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
            slug = "grist";
          })
        ];
      }
      {
        name = "Media Management";
        icon = "mdi-movie-open-settings";
        displayData.showForKeycloakUsers.groups = [ "Admins" ];
        items = [
          (mkEntry {
            slug = "sonarr";
          })
          (mkEntry {
            slug = "radarr";
          })
          (mkEntry {
            slug = "prowlarr";
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
        ];
      }
      {
        name = "Server Management";
        icon = "mdi-server";
        displayData.showForKeycloakUsers.groups = [ "Admins" ];
        items = [
          (mkEntry {
            slug = "cockpit";
            iconName = "cockpit-light";
          })
          (mkEntry {
            slug = "netdata";
          })
          (mkEntry {
            slug = "traefik";
          })
          (mkEntry {
            slug = "lldap";
            title = "LLDAP";
            iconName = "lldap-dark";
          })
        ];
      }
    ];
  };

in
pkgs.dashy-ui.override { settings = dashySettings; }
