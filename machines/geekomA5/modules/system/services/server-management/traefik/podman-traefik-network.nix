{ config, lib, pkgs, ... }:
{
  systemd = {
    services."podman-traefik-network" = {
      description = "Create Traefik Podman network";
      wantedBy = [ "multi-user.target" ];
      wants = [ "podman.service" ];
      after = [ "podman.service" ];

      serviceConfig = {
        ExecStart = lib.getExe (pkgs.writeShellApplication {
          name = "create-podman-traefik-network";
          runtimeInputs = [ config.virtualisation.podman.package ];
          text = ''
            podman network create \
              --subnet=172.31.0.0/24 \
              --gateway=172.31.0.1 \
              --driver=bridge \
              --ignore \
              traefik
          '';
        });
        Type = "oneshot";
      };
    };
  };
}
