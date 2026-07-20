{
  config,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;
in
{
  networking.firewall.interfaces."podman+" = {
    # Allows access to the MotionEye server & cameras from the container
    allowedTCPPorts = [
      portsCfg.motioneye.port
      portsCfg.motioneye-camera1.port
    ];
  };

  custom = {
    networking.ports.tcp = {
      motioneye = {
        port = 32600;
        openFirewall = false;
      };
      # Set manually in the mutable config files
      motion = {
        port = 32601;
        openFirewall = false;
      };

      # Technically can be changed in config files, but looks like it's hardcoded in MotionEye somewhere, because I've seen errors in logs after I changed it
      motioneye-camera1 = {
        port = 7999;
        openFirewall = false;
      };
    };

    services.caddy.hosts.motioneye = {
      upstream = "http://127.0.0.1:${portsCfg.motioneye.portStr}";
    };
  };

  services.motioneye = {
    enable = true;

    settings = {
      log_level = "info";
      listen = "0.0.0.0";
      port = portsCfg.motioneye.portStr;
      media_path = "/mnt/store/motioneye/media";
    };
  };
}
