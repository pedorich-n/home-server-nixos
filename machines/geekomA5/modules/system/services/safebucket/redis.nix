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

  services.redis.servers.safebucket = {
    enable = true;

    bind = "127.0.0.1";
    inherit (portsCfg) port;

    requirePassFile = config.sops.secrets."redis/safebucket/password".path;
  };
}
