{ config, dockerLib, authentikLib, lib, ... }:
let
  containerVersions = config.custom.containers.versions;

  storeFor = localPath: remotePath: "/mnt/store/grist/${localPath}:${remotePath}";
in
{
  virtualisation.quadlet.containers.grist = {
    containerConfig = rec {
      image = "gristlabs/grist:${containerVersions.grist}";
      name = "grist";
      networks = [ "traefik" ];
      environments = rec {
        GRIST_DOMAIN = "grist.${config.custom.networking.domain}";
        APP_HOME_URL = "http://${GRIST_DOMAIN}";

        GRIST_HIDE_UI_ELEMENTS = "billing";
        GRIST_SUPPORT_ANON = "false";

        GRIST_OIDC_SP_HOST = "${APP_HOME_URL}";
        GRIST_OIDC_IDP_ISSUER = authentikLib.mkIssuerUrl "grist";
        GRIST_OIDC_IDP_SCOPES = authentikLib.openIdScopes;
      };
      environmentFiles = [ config.age.secrets.grist.path ];
      volumes = [
        (storeFor "persist" "/persist")
      ];
      #TODO: make mkTraefikLabels return a list
      labels = lib.mapAttrsToList (name: value: "${name}=${value}") (dockerLib.mkTraefikLabels { inherit name; port = 8484; });
    };

    serviceConfig = {
      Restart = "unless-stopped";
    };

    unitConfig = {
      After = [
        "authentik.target"
      ];
    };
  };

}
