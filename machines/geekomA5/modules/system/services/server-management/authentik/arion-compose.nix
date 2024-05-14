{ config, pkgs, dockerLib, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/server-management/authentik/${localPath}:${remotePath}";

  defaultEnvs = {
    # https://docs.goauthentik.io/docs/installation/docker-compose#startup
    TZ = "UTC";

    AUTHENTIK_LOG_LEVEL = "info";

    AUTHENTIK_REDIS__HOST = "authentik-redis";
    AUTHENTIK_POSTGRESQL__HOST = "authentik-postgresql";
  };

  blueprints = pkgs.callPackage ./_render-blueprints.nix { inherit config; };

  authentikVersion = "2024.4.2";
in
{
  virtualisation.arion.projects = {
    authentik.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "authentik") // dockerLib.externalTraefikNetwork;

      services = {
        postgresql.service = {
          image = "docker.io/library/postgres:12.18-alpine";
          container_name = "authentik-postgresql";
          networks = [ "default" ];
          environment = defaultEnvs;
          user = "root";
          env_file = [ config.age.secrets.authentik_compose_main.path ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
          restart = "unless-stopped";
          labels = {
            "wud.watch" = "false"; # Fetch the version from authentik's docker-compose file
          };
        };

        redis.service = {
          image = "docker.io/library/redis:7.2.4-alpine";
          container_name = "authentik-redis";
          command = "--save 60 1 --loglevel warning";
          networks = [ "default" ];
          user = "root";
          volumes = [
            (storeFor "redis" "/data")
          ];
          restart = "unless-stopped";
          labels = {
            "wud.watch" = "false"; # Fetch the version from authentik's docker-compose file
          };
        };

        server.service = {
          image = "ghcr.io/goauthentik/server:${authentikVersion}";
          container_name = "authentik-server";
          command = "server";
          environment = defaultEnvs;
          user = "root";
          env_file = [ config.age.secrets.authentik_compose_main.path ];
          volumes = [
            (storeFor "media" "/media")
          ];
          depends_on = [ "postgresql" "redis" ];
          networks = {
            default = { };
            traefik = {
              ipv4_address = "172.31.0.240";
            };
          };
          labels = dockerLib.mkTraefikLabels { name = "authentik"; port = 9000; } // {
            "traefik.http.routers.authentik.priority" = "10";

            "traefik.http.routers.authentik-outpost.rule" = "HostRegexp(`{subdomain:[a-z0-9-]+}.${config.custom.networking.domain}`) && PathPrefix(`/outpost.goauthentik.io/`)";
            "traefik.http.routers.authentik-outpost.entrypoints" = "web";
            "traefik.http.routers.authentik-outpost.service" = "authentik";
            "traefik.http.routers.authentik-outpost.priority" = "15";

            "traefik.http.middlewares.authentik.forwardauth.address" = "http://172.31.0.240:9000/outpost.goauthentik.io/auth/traefik";
            "traefik.http.middlewares.authentik.forwardauth.trustForwardHeader" = "true";
            "traefik.http.middlewares.authentik.forwardauth.authResponseHeaders" = "X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version";
          };
          restart = "unless-stopped";
        };

        worker.service = {
          image = "ghcr.io/goauthentik/server:${authentikVersion}";
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
      };

    };
  };

}
