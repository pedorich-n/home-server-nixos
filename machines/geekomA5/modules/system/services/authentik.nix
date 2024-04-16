{ config, ... }:
let
  defaultEnvs = rec {
    # https://docs.goauthentik.io/docs/installation/docker-compose#startup
    TZ = "UTC";
    POSTGRES_USER = "authentik";
    POSTGRES_DB = "authentik";

    # generate via pwgen -s 40 1
    POSTGRES_PASSWORD = "7jFjT4pUyf0YOlQ84LrO6JdLVWpzKEGiEMtdVwBE";

    # generate via pwgen -s 50 1
    AUTHENTIK_SECRET_KEY = "YZRzXecsKQVEJ3Lr5uoKRGXZkETsYjUDT1qtQ28JjzWzDYvcoG";
    AUTHENTIK_REDIS__HOST = "authentik-redis";
    AUTHENTIK_POSTGRESQL__HOST = "authentik-postgresql";
    AUTHENTIK_POSTGRESQL__USER = "${POSTGRES_USER}";
    AUTHENTIK_POSTGRESQL__PASSWORD = "${POSTGRES_PASSWORD}";

    AUTHENTIK_LOG_LEVEL = "trace";
  };
in
{
  # services = {
  # authentik = {
  #   enable = true;
  #   environmentFile = ./authentik.env;
  #   settings = {
  #     nginx.enable = false;
  #     disable_startup_analytics = true;
  #     avatars = "initials";
  #   };
  # };


  virtualisation.arion.projects = {
    authentik.settings = {
      enableDefaultNetwork = false;

      networks = {
        default = {
          name = "internal-authentik";
          internal = true;
        };
        traefik = {
          name = "traefik";
          ipam = {
            config = [{
              subnet = "172.31.0.0/24";
              gateway = "172.31.0.1";
            }];
          };
        };
      };

      docker-compose.volumes = {
        database = {
          driver = "local";
        };
        redis = {
          driver = "local";
        };
        media = {
          driver = "local";
        };
      };

      services = {
        postgresql.service = {
          image = "docker.io/library/postgres:12-alpine";
          container_name = "authentik-postgresql";
          networks = [ "default" ];
          environment = defaultEnvs;
          # healthcheck = {
          #   test = [ "CMD-SHELL" "pg_isready -d authentik -U authentik" ];
          #   start_period = "20s";
          #   interval = "30s";
          #   retries = 5;
          #   timeout = "5s";
          # };
          volumes = [ "database:/var/lib/postgresql/data" ];
          restart = "unless-stopped";
        };

        redis.service = {
          image = "docker.io/library/redis:alpine";
          container_name = "authentik-redis";
          command = "--save 60 1 --loglevel warning";
          networks = [ "default" ];
          # healthcheck = {
          #   test = [ "CMD-SHELL" "redis-cli ping | grep PONG" ];
          #   start_period = "20s";
          #   interval = "30s";
          #   retries = 5;
          #   timeout = "3s";
          # };
          volumes = [ "redis:/data" ];
          restart = "unless-stopped";
        };

        server.service = {
          image = "ghcr.io/goauthentik/server:2024.2.2";
          container_name = "authentik-server";
          command = "server";
          environment = defaultEnvs;
          # user = "root";
          volumes = [
            "media:/media"
            # "custom-templates:/templates"
          ];
          depends_on = [ "postgresql" "redis" ];
          networks = [ "traefik" "default" ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.authentik.rule" = "Host(`authentik.${config.custom.networking.domain}`)";
            "traefik.http.routers.authentik.entrypoints" = "web";
            "traefik.http.routers.authentik.service" = "authentik";
            "traefik.http.services.authentik.loadBalancer.server.port" = "9000";


            "traefik.http.middlewares.authentik.forwardauth.address" = "http://authentik.${config.custom.networking.domain}/outpost.goauthentik.io/auth/traefik";
            "traefik.http.middlewares.authentik.forwardauth.trustForwardHeader" = "true";
            "traefik.http.middlewares.authentik.forwardauth.authResponseHeaders" = "X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version";
          };
          restart = "unless-stopped";
        };

        worker.service = {
          image = "ghcr.io/goauthentik/server:2024.2.2";
          container_name = "authentik-worker";
          command = "worker";
          user = "root";
          networks = [ "default" ];
          environment = defaultEnvs;
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
            "media:/media"
            # "certs:/certs"
            # "templates:/templates"
          ];
          depends_on = [ "postgresql" "redis" ];
          restart = "unless-stopped";
        };

        # proxy.service = {
        #   image = "ghcr.io/goauthentik/proxy:2024.2.2";
        #   container_name = "authentik-proxy";
        #   networks = [ "traefik" "default" ];
        #   environment = {
        #     AUTHENTIK_HOST = "http://${config.custom.networking.domain}";
        #     AUTHENTIK_TOKEN = "CHdeLmIAQaCNA1eL3e5D7U2QMcYLt8Sltkb3MLjPGYFSDw9SU4qpbqOcenVB";
        #   };
        #   labels = {
        #     "traefik.enable" = "true";
        #     "traefik.http.routers.authentik-outpost.rule" = "HostRegexp(`authentik-proxy.${config.custom.networking.domain}`)";
        #     "traefik.http.routers.authentik-outpost.entrypoints" = "web";
        #     "traefik.http.routers.authentik-outpost.service" = "authentik-outpost";
        #     "traefik.http.services.authentik-outpost.loadBalancer.server.port" = "9000";
        #   };
        # };
      };

    };
  };

  # traefik = {
  #   dynamicConfigOptions = {
  #     middlewares = {
  #       authentik = {
  #         forwardAuth = {
  #           address = "${config.custom.networking.domain}/outpost.goauthentik.io/auth/traefik";
  #           trustForwardHeader = true;
  #           authResponseHeaders = [
  #             "X-authentik-username"
  #             "X-authentik-groups"
  #             "X-authentik-email"
  #             "X-authentik-name"
  #             "X-authentik-uid"
  #             "X-authentik-jwt"
  #             "X-authentik-meta-jwks"
  #             "X-authentik-meta-outpost"
  #             "X-authentik-meta-provider"
  #             "X-authentik-meta-app"
  #             "X-authentik-meta-version"
  #           ];
  #         };
  #       };
  #     };

  #     routers = {
  #       # default = {
  #       #   rule = "Host(`${config.custom.networking.domain}`)";
  #       #   middlewares = [ "aithentik" ];
  #       #   priority = 10;
  #       #   service = "app";
  #       # };

  #       defaultAuth = {
  #         rule = "Host(`authentik.${config.custom.networking.domain}`) || HostRegexp(`{subdomain:[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?}.${config.custom.networking.domain}) && PathPrefix(`/outpost.goauthentik.io/`)";
  #         priority = 15;
  #         service = "aithentik";
  #       };
  #     };

  #     services = {
  #       # app = {
  #       #   loadBalancer = {
  #       #     servers = ["http://${config.custom.networking.domain}"];
  #       #   };
  #       # };

  #       authentik = {
  #         loadBalancer = {
  #           servers = [ "http://${config.custom.networking.domain}:9000/outpost.goauthentik.io" ];
  #         };
  #       };
  #     };
  #   };
  # };
  # };
}
