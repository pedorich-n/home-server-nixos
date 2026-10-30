{
  config,
  containerLib,
  systemdLib,
  ...
}:
let
  storeRoot = "/mnt/store/home-automation";

  networks = [ "home-automation-internal.network" ];

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

  portsCfg = config.custom.networking.ports.tcp;
in
{
  custom = {
    networking.ports.tcp.homeassistant = {
      port = 31800;
      openFirewall = false;
    };

    services.caddy.hosts.homeassistant = {
      upstream = "http://127.0.0.1:${portsCfg.homeassistant.portStr}";
    };
  };

  virtualisation.quadlet = {
    networks."home-automation-internal" = {
      networkConfig = {
        name = "home-automation-internal";
        driver = "bridge";
        # Hard-coded because HomeAssistant needs to know the trusted proxies subnet
        subnets = [ "172.32.0.0/24" ];
        gateways = [ "172.32.0.1" ];
      };
    };

    containers = {
      homeassistant = {
        useGlobalContainers = true;
        wantsCaddy = true;
        wantsAuthelia = true;
        usernsAuto = {
          enable = true;
          size = containerLib.containerIds.uid + 500;
        };

        containerConfig = {
          environments = {
            TZ = "${config.time.timeZone}";
          };
          addCapabilities = [ "NET_RAW" ];
          volumes = [
            (mkMappedVolumeForUserContainerRoot "${storeRoot}/homeassistant" "/config")
            (mkMappedVolumeForUserContainerRoot "${storeRoot}/homeassistant/local" "/.local")
            (mkMappedVolumeForUserContainerRoot config.sops.secrets."home-automation/homeassistant_secrets.yaml".path "/config/secrets.yaml")
          ];
          publishPorts = [ "127.0.0.1:${portsCfg.homeassistant.portStr}:8123" ];
          stopTimeout = 90;
          inherit networks;
        };

        serviceConfig = {
          TimeoutStopSec = 120;
        };

        unitConfig = systemdLib.requiresAfter [
          config.systemd.services.mosquitto.name
        ];
      };

    };
  };
}
