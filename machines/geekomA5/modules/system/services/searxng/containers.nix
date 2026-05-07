{
  config,
  containerLib,
  networkingLib,
  ...
}:
let
  storeRoot = "/mnt/store/searxng";

  portsCfg = config.custom.networking.ports.tcp.searxng;

  # SearXNG runs as 977:977 in the container, so we need to map the volume with the correct permissions.
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
          idNamespace = 977;
          idHost = config.users.users.user.uid;
        }
      ];

      gidMappings = [
        {
          idNamespace = 0;
          idHost = config.users.groups.${config.users.users.nobody.group}.gid;
        }
        {
          idNamespace = 977;
          idHost = config.users.groups.${config.users.users.user.group}.gid;
        }
      ];
    };
in
{
  custom = {
    networking.ports.tcp.searxng = {
      port = 30500;
      openFirewall = false;
    };

    services.caddy.hosts.searxng = {
      upstream = "http://localhost:${portsCfg.portStr}";
    };
  };

  virtualisation.quadlet.containers.searxng = {
    requiresTraefikNetwork = true;
    useGlobalContainers = true;
    usernsAuto.enable = true;

    containerConfig = {
      environments = {
        SEARXNG_BASE_URL = networkingLib.mkUrl "searxng";
      };
      environmentFiles = [ config.sops.secrets."searxng/main.env".path ];
      publishPorts = [ "127.0.0.1:${portsCfg.portStr}:8080" ];
      volumes = [
        (mkMappedVolumeForCustom "${storeRoot}/data" "/var/cache/searxng")
        (mkMappedVolumeForCustom "${storeRoot}/config" "/etc/searxng")
      ];
      labels = containerLib.mkTraefikLabels {
        name = "searxng";
        port = 8080;
      };
    };
  };

}
