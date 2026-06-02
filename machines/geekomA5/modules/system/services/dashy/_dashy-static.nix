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
      iconLink ? "https://cdn.jsdelivr.net/gh/selfhst/icons@main/png/${iconName}.png",
      args ? { },
    }:
    {
      inherit title;
      url = networkingLib.mkUrl slug;
      icon = iconLink;
      target = "newtab";
    }
    // args;

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
            slug = "maloja";
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
            args = {
              displayData.showForKeycloakUsers.groups = [ autheliaLib.groups.Admins ];
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
              displayData.showForKeycloakUsers.groups = [ autheliaLib.groups.Admins ];
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
            slug = "grist";
          })
        ];
      }
      {
        name = "Media Management";
        icon = "mdi-movie-open-settings";
        displayData.showForKeycloakUsers.groups = [ autheliaLib.groups.Admins ];
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
        ];
      }
      {
        name = "Server Management";
        icon = "mdi-server";
        displayData.showForKeycloakUsers.groups = [ autheliaLib.groups.Admins ];
        items = [
          (mkEntry {
            slug = "cockpit";
            iconName = "cockpit-light";
          })
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
