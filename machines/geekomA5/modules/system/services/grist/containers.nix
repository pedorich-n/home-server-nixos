{ config, containerLib, authentikLib, ... }:
let
  storeRoot = "/mnt/store/grist";

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
in
{
  virtualisation.quadlet.containers.grist = {
    requiresTraefikNetwork = true;
    wantsAuthentik = true;
    useGlobalContainers = true;
    usernsAuto = {
      enable = true;
      size = 65535;
    };

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
      volumes = [
        (mappedVolumeForUser "${storeRoot}/persist" "/persist")
      ];
      labels = containerLib.mkTraefikLabels { name = "grist"; port = 8484; };
      inherit user;
    };
  };

}
