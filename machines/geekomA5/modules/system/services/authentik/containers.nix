{ config, containerLib, systemdLib, jinja2RendererLib, ... }:
let
  storeRoot = "/mnt/store/server-management/authentik";

  containerIds = {
    uid = 1100;
    gid = 1100;
  };

  user = "${builtins.toString containerIds.uid}:${builtins.toString containerIds.gid}";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidNamespace = containerIds.uid;
        uidHost = config.users.users.user.uid;
        uidCount = 1;
        uidRelative = true;
        gidNamespace = containerIds.gid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
        gidCount = 1;
        gidRelative = true;
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

  blueprints = import ./_render-blueprints.nix { inherit jinja2RendererLib; };

  serverIp = "172.31.0.240";

  networks = [ "authentik-internal.network" ];
in
{
  virtualisation.quadlet = {
    networks = containerLib.mkDefaultNetwork "authentik";

    containers = {
      authentik-postgresql = {
        useGlobalContainers = true;
        usernsAuto = true;

        containerConfig = {
          environments = defaultEnvs;
          environmentFiles = [ config.age.secrets.authentik.path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/postgresql" "/var/lib/postgresql/data")
          ];
          inherit networks user;
        };
      };

      authentik-redis = {
        useGlobalContainers = true;
        usernsAuto = true;

        containerConfig = {
          exec = "--save 60 1 --loglevel warning";
          volumes = [
            (mappedVolumeForUser "${storeRoot}/redis" "/data")
          ];
          inherit networks user;
        };
      };

      authentik-worker = {
        useGlobalContainers = true;
        containerConfig = {
          exec = "worker";
          healthCmd = "ak healthcheck";
          healthStartPeriod = "20s";
          healthTimeout = "5s";
          healthInterval = "30s";
          healthRetries = 5;
          notify = "healthy";
          userns = "auto:size=65535";
          environments = defaultEnvs;
          environmentFiles = [ config.age.secrets.authentik.path ];
          volumes = [
            (mappedVolumeForUser "${storeRoot}/media" "/media")
            "${blueprints}:/blueprints/custom"
          ];
          inherit networks user;
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
          userns = "auto:size=65535";
          environmentFiles = [ config.age.secrets.authentik_ldap_outpost.path ];
          labels = [
            "traefik.enable=true"
            "traefik.tcp.services.authentik-ldap-outpost.loadBalancer.server.port=3389"
            "traefik.tcp.routers.authentik-ldap-outpost.rule=HostSNI(`*`)"
            "traefik.tcp.routers.authentik-ldap-outpost.entrypoints=ldap"
            "traefik.tcp.routers.authentik-ldap-outpost.service=authentik-ldap-outpost"
          ];
          inherit networks user;
        };
      };

      authentik-server = {
        useGlobalContainers = true;
        containerConfig = {
          exec = "server";
          environments = defaultEnvs;
          environmentFiles = [ config.age.secrets.authentik.path ];
          userns = "auto:size=65535";
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
            name = "authentik-outpost";
            rule = "'HostRegexp(`{subdomain:[a-z0-9-]+}.${config.custom.networking.domain}`) && PathPrefix(`/outpost.goauthentik.io/`)'";
            service = "authentik";
            priority = 15;
          }) ++ [
            "traefik.http.middlewares.authentik.forwardauth.address=http://${serverIp}:9000/outpost.goauthentik.io/auth/traefik"
            "traefik.http.middlewares.authentik.forwardauth.trustForwardHeader=true"
            "traefik.http.middlewares.authentik.forwardauth.authResponseHeaders=X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version"
          ];
          inherit user;
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
