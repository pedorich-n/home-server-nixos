{
  config,
  containerLib,
  networkingLib,
  ...
}:
let
  storeRoot = "/mnt/store/searxng";

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
  virtualisation.quadlet.containers.searxng = {
    requiresTraefikNetwork = true;
    useGlobalContainers = true;
    usernsAuto.enable = true;

    containerConfig = {
      environments = {
        SEARXNG_BASE_URL = networkingLib.mkUrl "searxng";
      };
      environmentFiles = [ config.sops.secrets."searxng/main.env".path ];
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
