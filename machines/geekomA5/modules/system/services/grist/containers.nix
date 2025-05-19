{ config, containerLib, authentikLib, networkingLib, ... }:
let
  storeRoot = "/mnt/store/grist";

  mappedVolumeForUser = localPath: remotePath:
    containerLib.mkIdmappedVolume
      {
        uidHost = config.users.users.user.uid;
        gidHost = config.users.groups.${config.users.users.user.group}.gid;
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
        GRIST_DOMAIN = networkingLib.mkExternalDomain "grist";
        APP_HOME_URL = networkingLib.mkExternalUrl "grist";

        GRIST_HIDE_UI_ELEMENTS = "billing";
        GRIST_SUPPORT_ANON = "false";

        GRIST_OIDC_SP_HOST = "${APP_HOME_URL}";
        GRIST_OIDC_IDP_ISSUER = authentikLib.mkExternalIssuerUrl "grist";
      };
      environmentFiles = [ config.sops.secrets."grist/main.env".path ];
      volumes = [
        (mappedVolumeForUser "${storeRoot}/persist" "/persist")
      ];
      labels = containerLib.mkTraefikLabels {
        name = "grist";
        port = 8484;
        domain = networkingLib.mkExternalDomain "grist";
        entrypoints = [ "web-secure" ];
      };
      inherit (containerLib.containerIds) user;
    };
  };

}
