{ config, pkgs, ... }: {
  networking.firewall = {
    allowedTCPPorts = [ 19999 ];
  };

  services.netdata = {
    enable = true;
    user = "user";
    group = "wheel";
    enableAnalyticsReporting = false;
    python.extraPackages = ps: [ ps.docker ];
    configDir = {
      "go.d/docker.conf" = pkgs.writeText "go.d/docker.conf" ''
        jobs:
          - name: docker-local
            address: 'unix:///var/run/docker.sock'
            collect_container_size: no
      '';
    };
    # config = {
    #   jobs = [{
    #     name = "docker-local";
    #     address = "unix:///var/run/docker.sock";
    #     collect_container_size = false;
    #   }];
    # };
  };
}
