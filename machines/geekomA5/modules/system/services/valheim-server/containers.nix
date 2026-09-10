{
  config,
  containerLib,
  ...
}:
let
  storeRoot = "/mnt/store/valheim-server";
  portsCfg = config.custom.networking.ports.udp;

  mkMappedVolumeForUserContainerRoot =
    hostPath: containerPath:
    containerLib.mkIdMappedVolume {
      inherit hostPath containerPath;
      uidMappings = [
        {
          idNamespace = 0;
          idHost = config.users.users.user.uid;
        }
      ];

      gidMappings = [
        {
          idNamespace = 0;
          idHost = config.users.groups.${config.users.users.user.group}.gid;
        }
      ];
    };
in
{
  custom = {
    networking.ports.udp = {
      valheim-server = {
        port = 2456;
        openFirewall = true;
      };
      valheim-server-query = {
        port = 2457;
        openFirewall = true;
      };
      valheim-server-cross = {
        port = 2458;
        openFirewall = true;
      };
    };
  };

  virtualisation.quadlet.containers.valheim-server = {
    useGlobalContainers = true;
    usernsAuto.enable = true;

    serviceConfig = {
      Restart = "always";
      # Upstream requires 2 min grace period for clean game shutdown
      TimeoutStopSec = "150";
    };

    containerConfig = {
      environments = {
        TZ = "${config.time.timeZone}";

        SERVER_NAME = "Just like the old times";
        WORLD_NAME = "Dedicated";
        SERVER_PUBLIC = "false";
        CROSSPLAY = "true";
        SUPERVISOR_HTTP = "false";
      };
      environmentFiles = [ config.sops.secrets."valheim-server/main.env".path ];
      volumes = [
        (mkMappedVolumeForUserContainerRoot "${storeRoot}/config" "/config")
        (mkMappedVolumeForUserContainerRoot "${storeRoot}/data" "/opt/valheim")
      ];
      publishPorts = [
        "0.0.0.0:${portsCfg.valheim-server.portStr}:2456/udp"
        "0.0.0.0:${portsCfg.valheim-server-query.portStr}:2457/udp"
        "0.0.0.0:${portsCfg.valheim-server-cross.portStr}:2458/udp"
      ];

      # Allows the Steam library that Valheim uses to give itself more CPU cycles.
      addCapabilities = [ "sys_nice" ];
    };
  };
}
