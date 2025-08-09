{
  config,
  containerLib,
  authentikLib,
  networkingLib,
  ...
}:
let
  storeRoot = "/mnt/store/grist";

  mappedVolumeForUser =
    localPath: remotePath:
    containerLib.mkIdmappedVolume {
      uidHost = config.users.users.user.uid;
      gidHost = config.users.groups.${config.users.users.user.group}.gid;
    } localPath remotePath;
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
        GRIST_DOMAIN = networkingLib.mkDomain "grist";
        APP_HOME_URL = networkingLib.mkUrl "grist";

        GRIST_HIDE_UI_ELEMENTS = "billing";
        GRIST_SUPPORT_ANON = "false";

        GRIST_OIDC_SP_HOST = "${APP_HOME_URL}";
        GRIST_OIDC_IDP_ISSUER = authentikLib.mkIssuerUrl "grist";

        # This function performs HTTP requests in a similar way to requests.request
        GRIST_ENABLE_REQUEST_FUNCTION = "1";
      };
      environmentFiles = [ config.sops.secrets."grist/main.env".path ];
      volumes = [
        (mappedVolumeForUser "${storeRoot}/persist" "/persist")
      ];
      labels = containerLib.mkTraefikLabels {
        name = "grist-secure";
        port = 8484;
      };
      inherit (containerLib.containerIds) user;
    };
  };

}
