{
  config,
  containerLib,
  autheliaLib,
  networkingLib,
  ...
}:
let
  storeRoot = "/mnt/store/trek";
  portsCfg = config.custom.networking.ports.tcp.trek;

  # Trek runs as 1000:1000 in the container, with no real way to remap it, so we need to map the volume with the correct permissions.
  mkMappedVolumeForCustom =
    hostPath: containerPath:
    containerLib.mkIdMappedVolume {
      inherit hostPath containerPath;
      uidMappings = [
        {
          idNamespace = 1000;
          idHost = config.users.users.user.uid;
        }
      ];

      gidMappings = [
        {
          idNamespace = 1000;
          idHost = config.users.groups.${config.users.users.user.group}.gid;
        }
      ];
    };
in
{
  custom = {
    networking.ports.tcp.trek = {
      port = 32300;
      openFirewall = false;
    };

    services.caddy.hosts.trek = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
      # See https://github.com/mauriceboe/TREK/wiki/Reverse-Proxy#caddy
      extraConfig = ''
        request_body max_size 500mb
      '';
    };
  };

  virtualisation.quadlet.containers.trek = {
    wantsCaddy = true;
    wantsAuthelia = true;
    useGlobalContainers = true;
    usernsAuto.enable = true;

    containerConfig = {
      environments = {
        NODE_ENV = "production";
        PORT = "3000";
        TZ = "${config.time.timeZone}";
        LOG_LEVEL = "info";

        ALLOWED_ORIGINS = networkingLib.mkUrl "trek";
        APP_URL = networkingLib.mkUrl "trek";
        ALLOW_INTERNAL_NETWORK = "true";

        OIDC_ISSUER = autheliaLib.issuerUrl;
        OIDC_DISCOVERY_URL = autheliaLib.discoveryUrl;
        OIDC_SCOPE = "openid profile email groups";
        OIDC_DISPLAY_NAME = "Authelia";
        OIDC_ONLY = "true";
        OIDC_ADMIN_CLAIM = "groups";
        OIDC_ADMIN_VALUE = autheliaLib.groups.Admins;

        SMTP_HOST = "smtp.purelymail.com";
        SMTP_PORT = "465";
      };
      environmentFiles = [ config.sops.secrets."trek/main.env".path ];
      volumes = [
        (mkMappedVolumeForCustom "${storeRoot}/data" "/app/data")
        (mkMappedVolumeForCustom "${storeRoot}/uploads" "/app/uploads")
      ];
      publishPorts = [ "127.0.0.1:${portsCfg.portStr}:3000" ];
      # inherit (containerLib.containerIds) user;
    };
  };

}
