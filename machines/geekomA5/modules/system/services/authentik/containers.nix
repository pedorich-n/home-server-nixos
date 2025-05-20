{ config, lib, containerLib, systemdLib, networkingLib, pkgs, ... }:
let
  storeRoot = "/mnt/store/server-management/authentik";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
      }
      localPath
      remotePath;

  defaultEnvs = {
    # https://docs.goauthentik.io/docs/installation/docker-compose#startup
    TZ = "UTC";

    AUTHENTIK_LOG_LEVEL = "info";

    AUTHENTIK_REDIS__HOST = "authentik-redis";
    AUTHENTIK_POSTGRESQL__HOST = "authentik-postgresql";
  };

  blueprints = pkgs.callPackage ./_render-blueprints.nix { domain = config.custom.networking.domain-external; };

  serverIp = "172.31.0.240";

  networks = [ "authentik-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "authentik";

    containers = {
      authentik-postgresql = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          environments = defaultEnvs;
          environmentFiles = [ config.sops.secrets."authentik/postgresql.env".path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      authentik-redis = {
        useGlobalContainers = true;
        usernsAuto.enable = true;

        containerConfig = {
          exec = "--save 60 1 --loglevel warning";
          volumes = [
            (mappedVolumeForUser "${storeRoot}/redis" "/data")
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      authentik-worker = {
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          exec = "worker";
          healthCmd = "ak healthcheck";
          healthStartPeriod = "20s";
          healthTimeout = "5s";
          healthInterval = "30s";
          healthRetries = 5;
          notify = "healthy";
          environments = defaultEnvs;
          environmentFiles = [ config.sops.secrets."authentik/main.env".path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/media" "/media")
            "${blueprints}:/blueprints/custom"
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };

        unitConfig = lib.mkMerge [
          (systemdLib.requiresAfter [
            "authentik-redis.service"
            "authentik-postgresql.service"
          ])
          {
            After = [ "authentik-server.service" ];
          }
        ];

        serviceConfig = {
          # Quite often the worker's healthcheck gets stuck for some reason. 
          # With this systemd will restart the worker if it's been "activating" for 5 minutes.
          TimeoutStartSec = 300;
        };
      };

      authentik-ldap = {
        requiresTraefikNetwork = true;
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          environments = defaultEnvs // {
            AUTHENTIK_HOST = networkingLib.mkExternalUrl "authentik";
          };
          environmentFiles = [ config.sops.secrets."authentik/ldap_outpost.env".path ];
          labels = [
            "traefik.enable=true"
            "traefik.tcp.services.authentik-ldap-outpost.loadBalancer.server.port=3389"
            "traefik.tcp.routers.authentik-ldap-outpost.rule=HostSNI(`*`)"
            "traefik.tcp.routers.authentik-ldap-outpost.entrypoints=ldap"
            "traefik.tcp.routers.authentik-ldap-outpost.service=authentik-ldap-outpost"
          ];
          inherit networks;
          inherit (containerLib.containerIds) user;
        };
      };

      authentik-server = {
        useGlobalContainers = true;
        usernsAuto = {
          enable = true;
          size = 65535;
        };

        containerConfig = {
          exec = "server";
          environments = defaultEnvs;
          environmentFiles = [ config.sops.secrets."authentik/main.env".path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/media" "/media")
          ];
          networks = networks ++ [
            "traefik.network:ip=${serverIp}"
          ];
          healthCmd = "ak healthcheck";
          healthStartPeriod = "20s";
          healthTimeout = "5s";
          healthInterval = "30s";
          healthRetries = 5;
          notify = "healthy";
          labels = (containerLib.mkTraefikLabels {
            name = "authentik";
            port = 9000;
            priority = 10;
          }) ++ (containerLib.mkTraefikLabels {
            name = "authentik-secure";
            domain = networkingLib.mkExternalDomain "authentik";
            service = "authentik";
            priority = 10;
            entrypoints = [ "web-secure" ];
          }) ++ (containerLib.mkTraefikLabels {
            name = "authentik-outpost-secure";
            rule = "HostRegexp(`${networkingLib.mkExternalDomain "{subdomain:[a-z0-9-]+}"}`) && PathPrefix(`/outpost.goauthentik.io/`)";
            service = "authentik";
            entrypoints = [ "web-secure" ];
            priority = 15;
          }) ++ [
            "traefik.http.middlewares.authentik-secure.forwardauth.address=http://${serverIp}:9000/outpost.goauthentik.io/auth/traefik"
            "traefik.http.middlewares.authentik-secure.forwardauth.trustForwardHeader=true"
            "traefik.http.middlewares.authentik-secure.forwardauth.authResponseHeaders=X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version"
          ];
          inherit (containerLib.containerIds) user;
        };

        unitConfig = systemdLib.requiresAfter [
          "authentik-redis.service"
          "authentik-postgresql.service"
        ];

        serviceConfig = {
          # Sometimes server's healthcheck gets stuck for some reason as well. 
          # With this systemd will restart the service if it's been "activating" for 5 minutes.
          TimeoutStartSec = 300;
        };
      };
    };
  };
}
