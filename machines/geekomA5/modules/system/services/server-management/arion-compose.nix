{ config, dockerLib, authentikLib, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/server-management/${localPath}:${remotePath}";

  # userSetting = "${toString config.users.users.user.uid}:${toString config.users.groups.docker.gid}";
in
{

  networking.firewall.interfaces."podman+" = {
    allowedTCPPorts = [
      config.custom.networking.ports.tcp.traefik-metrics.port # Metrics
    ];
  };

  virtualisation.arion.projects = {
    server-management.settings = {
      enableDefaultNetwork = false;

      networks = dockerLib.externalTraefikNetwork;

      services = {
        # homer.service = rec {
        #   image = "b4bz/homer:v24.04.1";
        #   container_name = "homer";
        #   networks = [ "traefik" ];
        #   restart = "unless-stopped";
        #   healthcheck.test = [ "NONE" ];
        #   user = userSetting;
        #   environment = {
        #     INIT_ASSETS = "1";
        #     PORT = "8080";
        #   };
        #   volumes = [
        #     # configuration file is managed by environment.mutable-files
        #     (storeFor "homer" "/www/assets")
        #   ];
        #   labels = (dockerLib.mkTraefikLabels {
        #     name = container_name;
        #     port = 8080;
        #     domain = config.custom.networking.domain;
        #   }) // {
        #     "wud.tag.exclude" = "^latest.*$";
        #   };
        # };

        homepage.service = rec {
          image = "ghcr.io/gethomepage/homepage:v0.9.1";
          container_name = "homepage";
          networks = [ "traefik" ];
          restart = "unless-stopped";
          # user = userSetting;
          volumes = [
            # Managed by environment.mutable-files
            (storeFor "homepage/config" "/app/config")
            (storeFor "homepage/images" "/app/public/images")

            "/run/podman/podman.sock:/var/run/docker.sock:ro"
          ];
          labels = (dockerLib.mkTraefikLabels {
            name = container_name;
            port = 3000;
            domain = config.custom.networking.domain;
          }) // {
            "wud.tag.exclude" = "^latest.*$";
          };
        };


        portainer.service = rec {
          image = "portainer/portainer-ce:2.20.2-alpine";
          container_name = "portainer";
          environment = {
            TZ = "${config.time.timeZone}";
          };
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock:ro"
            # "/var/run/docker.sock:/var/run/docker.sock:ro"
            (storeFor "portainer" "/data")
          ];
          networks = [ "traefik" ];
          # user = userSetting;
          restart = "unless-stopped";
          labels = dockerLib.mkTraefikLabels { name = container_name; port = 9000; } //
            (dockerLib.mkHomepageLabels {
              name = "Portainer";
              group = "Server";
              weight = 10;
            }) // {
            "wud.tag.include" = ''^\d+\.\d+(\.\d+)?-alpine$'';
            "wud.display.icon" = "si:portainer";
          };
        };

        whatsupdocker.service = rec {
          image = "fmartinou/whats-up-docker:6.3.0";
          container_name = "whatsupdocker";
          environment = {
            TZ = "${config.time.timeZone}";
            WUD_AUTH_OIDC_AUTHENTIK_DISCOVERY = authentikLib.mkIssuerUrl "whatsupdocker";
            WUD_AUTH_OIDC_AUTHENTIK_REDIRECT = "true";
          };
          env_file = [ config.age.secrets.server_management_compose.path ];
          networks = [ "traefik" ];
          restart = "unless-stopped";
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock:ro"
            (storeFor "whatsupdocker" "/store")
          ];
          labels = dockerLib.mkTraefikLabels { name = container_name; port = 3000; } //
            (dockerLib.mkHomepageLabels {
              name = "WhatsUpDocker";
              group = "Server";
              icon-slug = "whats-up-docker";
              weight = 20;
            }) // {
            "wud.tag.include" = ''^\d+\.\d+(\.\d+)?$'';
          };
        } // dockerLib.alpineHostsFix;
      };
    };
  };
}
