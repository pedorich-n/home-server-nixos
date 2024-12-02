{
  virtualisation.quadlet.networks = {
    traefik = {
      networkConfig = {
        name = "traefik";
        driver = "bridge";
        subnets = [ "172.31.0.0/24" ];
        gateways = [ "172.31.0.1" ];
      };
    };
  };
}
