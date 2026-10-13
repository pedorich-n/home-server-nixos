{
  config,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.redis-grist;
in
{
  custom.networking.ports.tcp = {
    redis-grist = {
      port = 31550;
      openFirewall = false;
    };
  };

  networking.firewall.interfaces."podman+" = {
    # Allows access to the Redis server from the container
    allowedTCPPorts = [
      portsCfg.port
    ];
  };

  services.redis.servers.grist = {
    enable = true;

    bind = "0.0.0.0"; # Listen on all interfaces, so that it can be accessed from the container
    inherit (portsCfg) port;

    settings = {
      protected-mode = "no";
    };
  };
}
