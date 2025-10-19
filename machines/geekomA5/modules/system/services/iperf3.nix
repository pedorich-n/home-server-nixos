{ config, ... }:
let
  portsCfg = config.custom.networking.ports.tcp.iperf3;

in
{
  custom.networking.ports.tcp.iperf3 = {
    port = 5201;
    openFirewall = true;
  };

  services.iperf3 = {
    enable = true;
    verbose = true;

    inherit (portsCfg) port;
  };
}
