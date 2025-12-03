{
  config,
  containerLib,
  autheliaLib,
  networkingLib,
  ...
}:
let
  storeRoot = "/mnt/store/linkding";

  # Service runs under www-data (uid/gid 33) inside the container chownsc files to that user.
  mkMappedVolumeForCustom =
    hostPath: containerPath:
    containerLib.mkIdMappedVolume {
      inherit hostPath containerPath;
      uidMappings = [
        {
          idNamespace = 0;
          idHost = config.users.users.nobody.uid;
        }
        {
          idNamespace = 33; # www-data
          idHost = config.users.users.user.uid;
        }
      ];

      gidMappings = [
        {
          idNamespace = 0;
          idHost = config.users.groups.${config.users.users.nobody.group}.gid;
        }
        {
          idNamespace = 33; # www-data
          idHost = config.users.groups.${config.users.users.user.group}.gid;
        }
      ];
    };
in
{
  virtualisation.quadlet.containers.linkding = {
    requiresTraefikNetwork = true;
    wantsAuthelia = true;
    useGlobalContainers = true;
    usernsAuto.enable = true;

    containerConfig = {
      environments = {
        LD_CSRF_TRUSTED_ORIGINS = networkingLib.mkUrl "linkding";

        LD_ENABLE_OIDC = "true";
        OIDC_OP_AUTHORIZATION_ENDPOINT = autheliaLib.authorizationUrl;
        OIDC_OP_TOKEN_ENDPOINT = autheliaLib.tokenUrl;
        OIDC_OP_USER_ENDPOINT = autheliaLib.userInfoUrl;
        OIDC_OP_JWKS_ENDPOINT = autheliaLib.jwksUrl;
        OIDC_USE_PKCE = "true";
        OIDC_VERIFY_SSL = "true";
        OIDC_RP_SCOPES = "openid email profile";
        OIDC_USERNAME_CLAIM = "preferred_username";

        LD_DISABLE_REQUEST_LOGS = "true";
      };
      environmentFiles = [ config.sops.secrets."linkding/main.env".path ];
      volumes = [
        (mkMappedVolumeForCustom "${storeRoot}/data" "/etc/linkding/data")
      ];
      labels = containerLib.mkTraefikLabels {
        name = "linkding";
        port = 9090;
      };
    };
  };

}
