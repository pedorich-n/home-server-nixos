{ pkgs, lib, ... }:
let
  regexes = {
    include = {
      # Matches 1.2.3, v1.2.3, 2024.1.1, etc.
      semverLike = "^v?\\d+\\.\\d+\\.\\d+";
      # Matches release-1.2.3.4
      arrStack = "^release-\\d+\\.\\d+\\.\\d+\\.\\d+$";
    };

    exclude = {
      rc = ".*rc.*";
    };
  };

  reusedContainers = {
    postgres16 = {
      registry = "docker.io";
      container = "library/postgres";
      include_regex = "^16\\.\\d+-alpine$";
    };

    redis7 = {
      registry = "docker.io";
      container = "library/redis";
      include_regex = "^7\\.\\d+\\.\\d+-alpine";
    };
  };

  containers = lib.mapAttrs (_: cfg: { source = "container"; } // cfg) {
    authentik = {
      registry = "ghcr.io";
      container = "goauthentik/server";
      exclude_regex = regexes.exclude.rc;
    };

    authentik-postgresql = reusedContainers.postgres16;

    authentik-redis = reusedContainers.redis7;

    grist = {
      registry = "docker.io";
      container = "gristlabs/grist";
    };

    mosquitto = {
      registry = "docker.io";
      container = "library/eclipse-mosquitto";
    };

    zigbee2mqtt = {
      registry = "docker.io";
      container = "koenkk/zigbee2mqtt";
    };

    nodered = {
      registry = "docker.io";
      container = "nodered/node-red";
      include_regex = regexes.include.semverLike;
    };

    homeassistant-mariadb = {
      registry = "docker.io";
      container = "library/mariadb";
      exclude_regex = regexes.exclude.rc;
    };

    homeassistant = {
      registry = "docker.io";
      container = "homeassistant/home-assistant";
      include_regex = regexes.include.semverLike;
    };

    homeassistant-postgresql = reusedContainers.postgres16;

    immich-server = {
      registry = "ghcr.io";
      container = "immich-app/immich-server";
      include_regex = regexes.include.semverLike;
    };

    immich-machine-learning = {
      registry = "ghcr.io";
      container = "immich-app/immich-machine-learning";
      include_regex = regexes.include.semverLike;
    };

    multi-scrobbler = {
      registry = "docker.io";
      container = "foxxmd/multi-scrobbler";
    };

    maloja = {
      registry = "docker.io";
      container = "krateng/maloja";
    };

    librechat-mongodb = {
      registry = "docker.io";
      container = "library/mongo";
      exclude_regex = regexes.exclude.rc;
    };

    librechat-server = {
      registry = "ghcr.io";
      container = "danny-avila/librechat";
      exclude_regex = regexes.exclude.rc;
    };

    librechat-rag = {
      registry = "ghcr.io";
      container = "danny-avila/librechat-rag-api-dev-lite";
    };

    librechat-vector = {
      registry = "docker.io";
      container = "ankane/pgvector";
    };

    paperless = {
      registry = "ghcr.io";
      container = "paperless-ngx/paperless-ngx";
    };

    paperless-postgresql = reusedContainers.postgres16;

    paperless-redis = reusedContainers.redis7;

    portainer = {
      registry = "docker.io";
      container = "portainer/portainer-ce";
      include_regex = regexes.include.semverLike;
    };

    sabnzbd = {
      registry = "lscr.io";
      container = "linuxserver/sabnzbd";
      include_regex = regexes.include.semverLike;
    };

    prowlarr = {
      registry = "ghcr.io";
      container = "hotio/prowlarr";
      include_regex = regexes.include.arrStack;
    };

    sonarr = {
      registry = "ghcr.io";
      container = "hotio/sonarr";
      include_regex = regexes.include.arrStack;
    };

    radarr = {
      registry = "ghcr.io";
      container = "hotio/radarr";
      include_regex = regexes.include.arrStack;
    };

    jellyfin = {
      registry = "docker.io";
      container = "jellyfin/jellyfin";
      include_regex = regexes.include.semverLike;
    };
  };

  config = {
    # https://nvchecker.readthedocs.io/en/latest/usage.html#configuration-files
    __config__ = {
      # This file doesn't have to exist, but the key must be defined
      oldver = "oldver.json";

      # nvchecker resolves env variables: https://github.com/lilydjwg/nvchecker/blob/d44a50c/nvchecker/core.py#L207-L208 
      newver = "\${TARGET}/versions.json";
    };
  } // containers;
in
pkgs.writers.writeTOML "nvchecker-containers.toml" config
