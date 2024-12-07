{ config, lib, containerLib, jinja2RendererLib, ... }:
let
  containerVersions = config.custom.containers.versions;

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

  withInternalNetwork = containerLib.mkWithNetwork "authentik-internal";
in
{
  systemd.targets.authentik = {
    wants = [
      "authentik-internal-network.service"
      "authentik-redis.service"
      "authentik-postgresql.service"
      "authentik-worker.service"
      "authentik-server.service"
    ];
  };


  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "authentik";

    containers = {
      authentik-postgresql = withInternalNetwork {
        containerConfig = {
          image = "docker.io/library/postgres:${containerVersions.authentik-postgresql}";
          name = "authentik-postgresql";
          environments = defaultEnvs;
          user = "root";
          environmentFiles = [ config.age.secrets.authentik.path ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
        };
      };

      authentik-redis = withInternalNetwork {
        containerConfig = {
          image = "docker.io/library/redis:${containerVersions.authentik-redis}";
          name = "authentik-redis";
          exec = "--save 60 1 --loglevel warning";
          user = "root";
          volumes = [
            (storeFor "redis" "/data")
          ];
        };
      };

      authentik-worker = withInternalNetwork {
        containerConfig = {
          image = "ghcr.io/goauthentik/server:${containerVersions.authentik}";
          name = "authentik-worker";
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
        };

        serviceConfig = {
          Environment = [
            ''PATH=${lib.makeBinPath [ "/run/wrappers" config.systemd.package ]}''
          ];
        };

        unitConfig = {
          Requires = [
            "authentik-redis.service"
            "authentik-postgresql.service"
          ];
          After = [
            "authentik-redis.service"
            "authentik-postgresql.service"
          ];
        };
      };

      authentik-server = withInternalNetwork {
        containerConfig = {
          image = "ghcr.io/goauthentik/server:${containerVersions.authentik}";
          name = "authentik-server";
          exec = "server";
          user = "root";
          environments = defaultEnvs;
          environmentFiles = [ config.age.secrets.authentik.path ];
          volumes = [
            (storeFor "media" "/media")
          ];
          networks = [
            "traefik:ip=${serverIp}"
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
            rule = "HostRegexp(`{subdomain:[a-z0-9-]+}.${config.custom.networking.domain}`) && PathPrefix(`/outpost.goauthentik.io/`)";
            service = "authentik";
            priority = 15;
          }) ++ [
            "traefik.http.middlewares.authentik.forwardauth.address=http://${serverIp}:9000/outpost.goauthentik.io/auth/traefik"
            "traefik.http.middlewares.authentik.forwardauth.trustForwardHeader=true"
            "traefik.http.middlewares.authentik.forwardauth.authResponseHeaders=X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version"
          ];
        };

        serviceConfig = {
          Environment = [
            ''PATH=${lib.makeBinPath [ "/run/wrappers" config.systemd.package ]}''
          ];
        };

        unitConfig = {
          Requires = [
            "authentik-redis.service"
            "authentik-postgresql.service"
          ];
          After = [
            "traefik-network.service"
          ];
        };
      };
    };
  };
}
