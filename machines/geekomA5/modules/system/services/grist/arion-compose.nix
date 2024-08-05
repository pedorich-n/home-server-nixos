{ config, dockerLib, authentikLib, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/grist/${localPath}:${remotePath}";

in
{
  systemd.services."arion-grist" = {
    after = [ "arion-authentik.service" ];
  };

  virtualisation.arion.projects = {
    grist.settings = {
      enableDefaultNetwork = false;

      networks = dockerLib.externalTraefikNetwork;

      services = {
        grist.service = rec {
          image = "gristlabs/grist:${containerVersions.grist}";
          container_name = "grist";
          networks = [
            "traefik"
          ];
          environment = rec {
            GRIST_DOMAIN = "grist.${config.custom.networking.domain}";
            APP_HOME_URL = "http://${GRIST_DOMAIN}";

            GRIST_HIDE_UI_ELEMENTS = "billing";
            GRIST_SUPPORT_ANON = "false";

            GRIST_OIDC_SP_HOST = "${APP_HOME_URL}";
            GRIST_OIDC_IDP_ISSUER = authentikLib.mkIssuerUrl "grist";
            GRIST_OIDC_IDP_SCOPES = authentikLib.openIdScopes;
          };
          env_file = [ config.age.secrets.grist_compose.path ];
          restart = "unless-stopped";
          volumes = [
            (storeFor "persist" "/persist")
          ];
          labels =
            (dockerLib.mkTraefikLabels { name = container_name; port = 8484; }) //
            (dockerLib.mkHomepageLabels {
              name = "Grist";
              group = "Services";
              weight = 20;
            });
        };
      };
    };
  };
}
