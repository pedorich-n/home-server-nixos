{ config, lib, pkgs, dockerLib, ... }:
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

  blueprints = pkgs.callPackage ./_render-blueprints.nix { inherit config; };

  staticIpAddresses = {
    server = "172.31.0.240";
  };
in
{
  systemd.services."arion-authentik".serviceConfig = {
    Type = "notify";
    NotifyAccess = "all";
    TimeoutStartSec = "180";
    ExecStart = lib.mkForce (lib.getExe (pkgs.writeShellApplication {
      name = "authentik-healthcheck";
      runtimeInputs = [
        config.virtualisation.podman.package
        config.systemd.package
        pkgs.coreutils
      ];
      text = ''
        function watchdog() {
          MAX_RETRIES="11"
          RETRY_DELAY="15"
          TIMEOUT="10"

          exit_code=-1
          attempt=1

          sleep 2s
          echo "Healthchecking..."
          while [ ''${attempt} -lt ''${MAX_RETRIES} ]; do
            set +e  # Disable exit on error for this function
            output=$(timeout ''${TIMEOUT} podman exec --tty authentik-server ak healthcheck 2>&1)
            exit_code=$?

            if [ $exit_code -eq 0 ]; then
              echo "Health check passed"
              systemd-notify --ready --status="Service is up and running"
              exit 0
            else
              echo "Attempt $((attempt)) failed with exit code ''${exit_code}"
              attempt=$((attempt + 1))

              sleep "''${RETRY_DELAY}s"
            fi
          done

          systemd-notify --status="Service is not responding..."
          printf "Last output is:\n%s" "''${output}"
          exit 1
        }

        watchdog &

        echo 1>&2 "docker compose file: $ARION_PREBUILT"
        arion --prebuilt-file "$ARION_PREBUILT" up
      '';
      #NOTE - `arion` command copied from https://github.com/hercules-ci/arion/blob/90bc85532767c785245f5c1e29ebfecb941cf8c9/nixos-module.nix#L45-L48
    }));
  };

  virtualisation.arion.projects = {
    authentik.settings = {
      enableDefaultNetwork = false;

      networks = (dockerLib.mkDefaultNetwork "authentik") // dockerLib.externalTraefikNetwork;

      services = {
        postgresql.service = {
          image = "docker.io/library/postgres:${containerVersions.authentik-postgres}";
          container_name = "authentik-postgresql";
          networks = [ "default" ];
          environment = defaultEnvs;
          user = "root";
          env_file = [ config.age.secrets.authentik_compose_main.path ];
          volumes = [
            (storeFor "postgresql" "/var/lib/postgresql/data")
          ];
          restart = "unless-stopped";
        };

        redis.service = {
          image = "docker.io/library/redis:${containerVersions.authentik-redis}";
          container_name = "authentik-redis";
          command = "--save 60 1 --loglevel warning";
          networks = [ "default" ];
          user = "root";
          volumes = [
            (storeFor "redis" "/data")
          ];
          restart = "unless-stopped";
        };

        server.service = {
          image = "ghcr.io/goauthentik/server:${containerVersions.authentik}";
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
              ipv4_address = staticIpAddresses.server;
            };
          };
          labels = (dockerLib.mkTraefikLabels {
            name = "authentik";
            port = 9000;
            priority = 10;
          }) // (dockerLib.mkTraefikLabels {
            name = "authentik-outpost";
            rule = "HostRegexp(`{subdomain:[a-z0-9-]+}.${config.custom.networking.domain}`) && PathPrefix(`/outpost.goauthentik.io/`)";
            service = "authentik";
            priority = 15;
          }) // {
            "traefik.http.middlewares.authentik.forwardauth.address" = "http://${staticIpAddresses.server}:9000/outpost.goauthentik.io/auth/traefik";
            "traefik.http.middlewares.authentik.forwardauth.trustForwardHeader" = "true";
            "traefik.http.middlewares.authentik.forwardauth.authResponseHeaders" = "X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version";
          } // (dockerLib.mkHomepageLabels {
            name = "Authentik";
            group = "Server";
            weight = 70;
          });
          restart = "unless-stopped";
        };

        worker.service = {
          image = "ghcr.io/goauthentik/server:${containerVersions.authentik}";
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
