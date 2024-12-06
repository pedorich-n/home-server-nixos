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
in
{
  # systemd.services."arion-authentik".serviceConfig = {
  #   Type = "notify";
  #   NotifyAccess = "all";
  #   TimeoutStartSec = "180";
  #   ExecStart = lib.mkForce (lib.getExe (pkgs.writeShellApplication {
  #     name = "authentik-healthcheck";
  #     runtimeInputs = [
  #       config.virtualisation.podman.package
  #       config.systemd.package
  #       pkgs.coreutils
  #     ];
  #     text = ''
  #       function watchdog() {
  #         MAX_RETRIES="11"
  #         RETRY_DELAY="15"
  #         TIMEOUT="10"

  #         exit_code=-1
  #         attempt=1

  #         sleep 2s
  #         echo "Healthchecking..."
  #         while [ ''${attempt} -lt ''${MAX_RETRIES} ]; do
  #           set +e  # Disable exit on error for this function
  #           output=$(timeout ''${TIMEOUT} podman exec --tty authentik-server ak healthcheck 2>&1)
  #           exit_code=$?

  #           if [ $exit_code -eq 0 ]; then
  #             echo "Health check passed"
  #             systemd-notify --ready --status="Service is up and running"
  #             exit 0
  #           else
  #             echo "Attempt $((attempt)) failed with exit code ''${exit_code}"
  #             attempt=$((attempt + 1))

  #             sleep "''${RETRY_DELAY}s"
  #           fi
  #         done

  #         systemd-notify --status="Service is not responding..."
  #         printf "Last output is:\n%s" "''${output}"
  #         exit 1
  #       }

  #       watchdog &

  #       echo 1>&2 "docker compose file: $ARION_PREBUILT"
  #       arion --prebuilt-file "$ARION_PREBUILT" up
  #     '';
  #     #NOTE - `arion` command copied from https://github.com/hercules-ci/arion/blob/90bc85532767c785245f5c1e29ebfecb941cf8c9/nixos-module.nix#L45-L48
  #   }));
  # };

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
      authentik-postgresql = {
        containerConfig = {
          image = "docker.io/library/postgres:${containerVersions.authentik-postgresql}";
          name = "authentik-postgresql";
          networks = [ "authentik-internal" ];
          environments = defaultEnvs;
          user = "root";
          environmentFiles = [ config.age.secrets.authentik.path ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
        };

        unitConfig = {
          Requires = [
            "authentik-internal-network.service"
          ];
        };
      };

      authentik-redis = {
        containerConfig = {
          image = "docker.io/library/redis:${containerVersions.authentik-redis}";
          name = "authentik-redis";
          exec = "--save 60 1 --loglevel warning";
          networks = [ "authentik-internal" ];
          user = "root";
          volumes = [
            (storeFor "redis" "/data")
          ];
        };

        unitConfig = {
          Requires = [
            "authentik-internal-network.service"
          ];
        };
      };

      authentik-worker = {
        containerConfig = {
          image = "ghcr.io/goauthentik/server:${containerVersions.authentik}";
          name = "authentik-worker";
          exec = "worker";
          user = "root";
          networks = [ "authentik-internal" ];
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
            "authentik-internal-network.service"
            "authentik-redis.service"
            "authentik-postgresql.service"
          ];
        };
      };

      authentik-server = {
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
            "authentik-internal"
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
            "authentik-internal-network.service"
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
