{
  config,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.redis-safebucket;
in
{
  custom.networking.ports.tcp.redis-safebucket = {
    port = 32950;
    openFirewall = false;
  };

  networking.firewall.interfaces."podman+" = {
    # Allows access to the Redis server from the container
    allowedTCPPorts = [
      portsCfg.port
    ];
  };

  services.redis.servers.safebucket = {
    enable = true;

    bind = "0.0.0.0"; # Listen on all interfaces, so that it can be accessed from the container
    inherit (portsCfg) port;

    settings = {
      protected-mode = "no";
    };
  };
}
