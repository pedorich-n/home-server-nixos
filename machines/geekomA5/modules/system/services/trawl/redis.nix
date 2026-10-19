{
  config,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.redis-trawl;
in
{
  custom.networking.ports.tcp.redis-trawl = {
    port = 33250;
    openFirewall = false;
  };

  # Allows the Trawl quadlet container to reach Redis over the podman+ bridge.
  networking.firewall.interfaces."podman+" = {
    allowedTCPPorts = [
      portsCfg.port
    ];
  };

  services.redis.servers.trawl = {
    enable = true;

    bind = "0.0.0.0"; # Listen on all interfaces, so that it can be accessed from the container
    inherit (portsCfg) port;

    settings = {
      protected-mode = "no";
    };
  };
}
