{ config, pkgs, dockerLib, ... }:
let
  version = "2024.2.2";

  storeFor = localPath: remotePath: "/mnt/store/server-management/authentik/${localPath}:${remotePath}";

  defaultEnvs = {
    # https://docs.goauthentik.io/docs/installation/docker-compose#startup
    TZ = "UTC";

    AUTHENTIK_LOG_LEVEL = "info";

    AUTHENTIK_REDIS__HOST = "authentik-redis";
    AUTHENTIK_POSTGRESQL__HOST = "authentik-postgresql";
  };

  blueprints = pkgs.callPackage ./_render-blueprints.nix { inherit config; };
in
{
  virtualisation.arion.projects = {
    authentik.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "authentik") // dockerLib.externalTraefikNetwork;

      services = {
        postgresql.service = {
          image = "docker.io/library/postgres:12-alpine";
          container_name = "authentik-postgresql";
          networks = [ "default" ];
          environment = defaultEnvs;
          user = "root";
          env_file = [ config.age.secrets.authentik_compose_main.path ];
          healthcheck = {
            test = [ "CMD-SHELL" "pg_isready -d authentik -U authentik" ];
            start_period = "20s";
            interval = "30s";
            retries = 5;
            timeout = "5s";
          };
          volumes = [
            (storeFor "postgres" "/var/lib/postgresql/data")
          ];
          restart = "unless-stopped";
        };

        redis.service = {
          image = "docker.io/library/redis:alpine";
          container_name = "authentik-redis";
          command = "--save 60 1 --loglevel warning";
          networks = [ "default" ];
          user = "root";
          healthcheck = {
            test = [ "CMD-SHELL" "redis-cli ping | grep PONG" ];
            start_period = "20s";
            interval = "30s";
            retries = 5;
            timeout = "3s";
          };
          volumes = [
            (storeFor "redis" "/data")
          ];
          restart = "unless-stopped";
        };

        server.service = {
          image = "ghcr.io/goauthentik/server:${version}";
          container_name = "authentik-server";
          command = "server";
          environment = defaultEnvs;
          user = "root";
          env_file = [ config.age.secrets.authentik_compose_main.path ];
          volumes = [
            (storeFor "media" "/media")
          ];
          depends_on = [ "postgresql" "redis" ];
          networks = [ "traefik" "default" ];
          labels = dockerLib.mkTraefikLabels { name = "authentik"; port = 9000; } // {
            "traefik.http.routers.authentik.priority" = "10";
          };
          restart = "unless-stopped";
        };

        worker.service = {
          image = "ghcr.io/goauthentik/server:${version}";
          container_name = "authentik-worker";
          command = "worker";
          user = "root";
          networks = [ "default" ];
          environment = defaultEnvs;
          env_file = [ config.age.secrets.authentik_compose_main.path ];
          volumes = [
            (storeFor "media" "/media")
            "${blueprints}:/blueprints/custom"
          ];
          depends_on = [ "postgresql" "redis" ];
          restart = "unless-stopped";
        };

        outpost.service = rec {
          image = "ghcr.io/goauthentik/proxy:${version}";
          container_name = "authentik-outpost";
          networks = {
            default = { };
            traefik = {
              ipv4_address = "172.31.0.240";
            };
          };
          environment = defaultEnvs // {
            AUTHENTIK_HOST = "http://authentik-server:9000";
            AUTHENTIK_HOST_BROWSER = "http://authentik.${config.custom.networking.domain}";
            # AUTHENTIK_DEBUG = "true";
          };
          env_file = [ config.age.secrets.authentik_outpost.path ];
          labels = dockerLib.mkTraefikLabels { name = container_name; port = 9000; } // {
            "traefik.http.routers.authentik-outpost.rule" = "HostRegexp(`{subdomain:[a-z0-9-]+}.${config.custom.networking.domain}`) && PathPrefix(`/outpost.goauthentik.io/`)";
            "traefik.http.routers.authentik-outpost.priority" = "15";

            "traefik.http.middlewares.authentik.forwardauth.address" = "http://172.31.0.240:9000/outpost.goauthentik.io/auth/traefik";
            "traefik.http.middlewares.authentik.forwardauth.trustForwardHeader" = "true";
            "traefik.http.middlewares.authentik.forwardauth.authResponseHeaders" = "X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version";
          };
        };

      };

    };
  };

}
