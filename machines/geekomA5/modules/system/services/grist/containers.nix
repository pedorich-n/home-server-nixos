{ config, containerLib, authentikLib, ... }:
let
  storeRoot = "/mnt/store/grist";

  mappedVolumeForUser = uidNamespace: gidNamespace: localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        inherit uidNamespace;
        uidHost = config.users.users.user.uid;
        uidCount = 1;
        uidRelative = true;
        inherit gidNamespace;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
        gidCount = 1;
        gidRelative = true;
      }
      localPath
      remotePath;
in
{
  virtualisation.quadlet.containers.grist = {
    requiresTraefikNetwork = true;
    wantsAuthentik = true;
    useGlobalContainers = true;

    containerConfig = {
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
      user = "1100:1100";
      userns = "auto:size=65535";
      volumes = [
        (mappedVolumeForUser 1100 1100 "${storeRoot}/persist" "/persist")
      ];
      labels = containerLib.mkTraefikLabels { name = "grist"; port = 8484; };
    };
  };

}
