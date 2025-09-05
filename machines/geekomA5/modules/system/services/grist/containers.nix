{
  config,
  containerLib,
  autheliaLib,
  networkingLib,
  ...
}:
let
  storeRoot = "/mnt/store/grist";
in
{
  virtualisation.quadlet.containers.grist = {
    requiresTraefikNetwork = true;
    wantsAuthelia = true;
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
        GRIST_OIDC_IDP_ISSUER = autheliaLib.issuerUrl;
        GRIST_OIDC_IDP_SKIP_END_SESSION_ENDPOINT = "true";

        # This function performs HTTP requests in a similar way to requests.request
        GRIST_ENABLE_REQUEST_FUNCTION = "1";
      };
      environmentFiles = [ config.sops.secrets."grist/main.env".path ];
      volumes = [
        (containerLib.mkMappedVolumeForUser "${storeRoot}/persist" "/persist")
      ];
      labels = containerLib.mkTraefikLabels {
        name = "grist-secure";
        port = 8484;
      };
      inherit (containerLib.containerIds) user;
    };
  };

}
