{ pkgs, lib, ... }:
let
  regexes = {
    # Matches 1.2.3, v1.2.3, 2024.1.1, etc.
    semverLike = "^v?\\d+\\.\\d+\\.\\d+";

    rc = ".*rc.*";
  };


  registries =
    let
      mkWithRegistry = registry: config: { inherit registry; } // config;
    in
    {
      ghcr = mkWithRegistry "ghcr.io";
      docker = mkWithRegistry "docker.io";
      lscr = mkWithRegistry "lscr.io";
    };

  reusedContainers = {
    postgres16 = registries.docker {
      container = "library/postgres";
      include_regex = "^16\\.\\d+-alpine$";
    };

    redis7 = registries.docker {
      container = "library/redis";
      include_regex = "^7\\.\\d+\\.\\d+-alpine";
    };
  };

  makers = {
    mkAuthentik = name: registries.ghcr {
      container = "goauthentik/${name}";
      exclude_regex = regexes.rc;
    };

    mkArr = name: registries.ghcr {
      container = "hotio/${name}";
      # Matches release-1.2.3.4
      include_regex = "^release-\\d+\\.\\d+\\.\\d+\\.\\d+$";
    };
  };

  containers = {
    authentik-server = makers.mkAuthentik "server";

    authentik-worker = makers.mkAuthentik "server";

    authentik-ldap = makers.mkAuthentik "ldap";

    authentik-postgresql = reusedContainers.postgres16;

    authentik-redis = reusedContainers.redis7;

    grist = registries.docker {
      container = "gristlabs/grist";
    };

    mosquitto = registries.docker {
      container = "library/eclipse-mosquitto";
    };

    zigbee2mqtt = registries.docker {
      container = "koenkk/zigbee2mqtt";
    };

    nodered = registries.docker {
      container = "nodered/node-red";
      include_regex = regexes.semverLike;
    };

    homeassistant-mariadb = registries.docker {
      container = "library/mariadb";
      exclude_regex = regexes.rc;
    };

    homeassistant = registries.docker {
      container = "homeassistant/home-assistant";
      include_regex = regexes.semverLike;
    };

    homeassistant-postgresql = reusedContainers.postgres16;

    immich-server = registries.ghcr {
      container = "immich-app/immich-server";
      include_regex = regexes.semverLike;
    };

    immich-machine-learning = registries.ghcr {
      container = "immich-app/immich-machine-learning";
      include_regex = regexes.semverLike;
    };

    multiscrobbler = registries.docker {
      container = "foxxmd/multi-scrobbler";
    };

    maloja = registries.docker {
      container = "krateng/maloja";
    };

    librechat-mongodb = registries.docker {
      container = "library/mongo";
      exclude_regex = regexes.rc;
    };

    librechat-server = registries.ghcr {
      container = "danny-avila/librechat";
      exclude_regex = regexes.rc;
    };

    librechat-rag = registries.ghcr {
      container = "danny-avila/librechat-rag-api-dev-lite";
    };

    librechat-vector = registries.docker {
      container = "ankane/pgvector";
    };

    paperless-server = registries.ghcr {
      container = "paperless-ngx/paperless-ngx";
    };

    paperless-postgresql = reusedContainers.postgres16;

    paperless-redis = reusedContainers.redis7;

    portainer = registries.docker {
      container = "portainer/portainer-ce";
      include_regex = regexes.semverLike;
    };

    sabnzbd = registries.lscr {
      container = "linuxserver/sabnzbd";
      include_regex = regexes.semverLike;
    };

    prowlarr = makers.mkArr "prowlarr";

    sonarr = makers.mkArr "sonarr";

    radarr = makers.mkArr "radarr";

    jellyfin = registries.docker {
      container = "jellyfin/jellyfin";
      include_regex = regexes.semverLike;
    };
  };

  config = {
    # https://nvchecker.readthedocs.io/en/latest/usage.html#configuration-files
    __config__ = {
      # This file doesn't have to exist, but the key must be defined
      oldver = "oldver.json";

      # nvchecker resolves env variables: https://github.com/lilydjwg/nvchecker/blob/d44a50c/nvchecker/core.py#L207-L208 
      newver = "\${TARGET}/output.json";
    };
  } // (lib.mapAttrs (_: cfg: { source = "container"; } // cfg) containers);


  cleanedContainers = lib.mapAttrs (_: container: lib.filterAttrs (name: _: builtins.elem name [ "registry" "container" ]) container) containers;
in
{
  nvcheckerToml = pkgs.writers.writeTOML "nvchecker-containers.toml" config;
  containersJson = pkgs.writers.writeJSON "containers.json" cleanedContainers;
}

