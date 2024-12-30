{ config, containerLib, systemdLib, jinja2RendererLib, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/server-management/authentik/${localPath}:${remotePath}";

  defaultEnvs = {
    # https://docs.goauthentik.io/docs/installation/docker-compose#startup
    TZ = "UTC";

    AUTHENTIK_LOG_LEVEL = "info";

    AUTHENTIK_REDIS__HOST = "authentik-redis";
    AUTHENTIK_POSTGRESQL__HOST = "authentik-postgresql";
  };

  blueprints = import ./_render-blueprints.nix { inherit jinja2RendererLib; };

  serverIp = "172.31.0.240";

  pod = "authentik.pod";
  networks = [ "authentik-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "authentik";

    pods.authentik = {
      podConfig = { inherit networks; };
    };

    containers = {
      authentik-postgresql = {
        useGlobalContainers = true;
        useProvidedHealthcheck = true;

        containerConfig = {
          environments = defaultEnvs;
          user = "root";
          environmentFiles = [ config.age.secrets.authentik.path ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks pod;
        };
      };

      authentik-redis = {
        useGlobalContainers = true;
        useProvidedHealthcheck = true;

        containerConfig = {
          exec = "--save 60 1 --loglevel warning";
          user = "root";
          volumes = [
            (storeFor "redis" "/data")
          ];
          inherit networks pod;
        };
      };

      authentik-worker = {
        useGlobalContainers = true;
        containerConfig = {
          exec = "worker";
          user = "root";
          healthCmd = "ak healthcheck";
          healthStartPeriod = "20s";
          healthTimeout = "5s";
          healthRetries = 5;
          notify = "healthy";
          environments = defaultEnvs;
          environmentFiles = [ config.age.secrets.authentik.path ];
          volumes = [
            (storeFor "media" "/media")
            "${blueprints}:/blueprints/custom"
          ];
          inherit networks pod;
        };

        unitConfig = systemdLib.requiresAfter
          [
            "authentik-redis.service"
            "authentik-postgresql.service"
          ]
          {
            After = [ "authentik-server.service" ];
          };

        serviceConfig = {
          # Quite often the worker's healthcheck gets stuck for some reason. 
          # With this systemd will restart the worker if it's been "activating" for 5 minutes.
          TimeoutStartSec = 300;
        };
      };

      authentik-ldap = {
        useGlobalContainers = true;
        containerConfig = {
          environments = defaultEnvs // {
            AUTHENTIK_HOST = "http://authentik.${config.custom.networking.domain}";
          };
          environmentFiles = [ config.age.secrets.authentik_ldap_outpost.path ];
          labels = [
            "traefik.enable=true"
            "traefik.tcp.services.authentik-ldap-outpost.loadBalancer.server.port=3389"
            "traefik.tcp.routers.authentik-ldap-outpost.rule=HostSNI(`*`)"
            "traefik.tcp.routers.authentik-ldap-outpost.entrypoints=ldap"
            "traefik.tcp.routers.authentik-ldap-outpost.service=authentik-ldap-outpost"
          ];
          inherit networks pod;
        };
      };

      authentik-server = {
        useGlobalContainers = true;
        containerConfig = {
          exec = "server";
          user = "root";
          environments = defaultEnvs;
          environmentFiles = [ config.age.secrets.authentik.path ];
          volumes = [
            (storeFor "media" "/media")
          ];
          networks = networks ++ [
            "traefik.network:ip=${serverIp}"
          ];
          healthCmd = "ak healthcheck";
          healthStartPeriod = "20s";
          healthTimeout = "5s";
          healthRetries = 5;
          notify = "healthy";
          labels = (containerLib.mkTraefikLabels {
            name = "authentik";
            port = 9000;
            priority = 10;
          }) ++ (containerLib.mkTraefikLabels {
            name = "authentik-outpost";
            rule = "'HostRegexp(`{subdomain:[a-z0-9-]+}.${config.custom.networking.domain}`) && PathPrefix(`/outpost.goauthentik.io/`)'";
            service = "authentik";
            priority = 15;
          }) ++ [
            "traefik.http.middlewares.authentik.forwardauth.address=http://${serverIp}:9000/outpost.goauthentik.io/auth/traefik"
            "traefik.http.middlewares.authentik.forwardauth.trustForwardHeader=true"
            "traefik.http.middlewares.authentik.forwardauth.authResponseHeaders=X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version"
          ];
          inherit pod;
        };

        unitConfig = systemdLib.requiresAfter
          [
            "authentik-redis.service"
            "authentik-postgresql.service"
          ]
          { };

        serviceConfig = {
          # Sometimes server's healthcheck gets stuck for some reason as well. 
          # With this systemd will restart the service if it's been "activating" for 5 minutes.
          TimeoutStartSec = 300;
        };
      };
    };
  };
}
