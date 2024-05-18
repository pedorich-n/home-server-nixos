{ config, dockerLib, ... }:
let
  storeFor = localPath: remotePath: "/mnt/store/grist/${localPath}:${remotePath}";

in
{
  virtualisation.arion.projects = {
    grist.settings = {
      enableDefaultNetwork = false;

      networks = dockerLib.externalTraefikNetwork;

      services = {
        grist.service = rec {
          image = "gristlabs/grist:1.1.14";
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
            GRIST_OIDC_IDP_ISSUER = "http://authentik.${config.custom.networking.domain}/application/o/grist/.well-known/openid-configuration";
            GRIST_OIDC_IDP_SCOPES = "openid profile email";
          };
          env_file = [ config.age.secrets.grist_compose.path ];
          restart = "unless-stopped";
          volumes = [
            (storeFor "persist" "/persist")
          ];
          labels =
            (dockerLib.mkTraefikLabels { name = container_name; port = 8484; }) //
            {
              "wud.tag.include" = ''^\d+\.\d+\.\d+'';
            };
        };
      };
    };
  };
}
