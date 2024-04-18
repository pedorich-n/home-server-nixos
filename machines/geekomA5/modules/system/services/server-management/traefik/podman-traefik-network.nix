{ config, lib, pkgs, ... }:
let
  serviceName = "podman-traefik-network";
in
{
  systemd = {
    services.${serviceName} = {
      description = "Create Traefik Podman network";
      wantedBy = [ "multi-user.target" ];

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

    packages = [
      # Make all arion-* systemd services start only after the traefik network exists
      (pkgs.writeTextDir "/etc/systemd/system/arion-.service.d/90-wait-for-podman-network.conf" ''
        [Unit]
        After=${serviceName}.service
      '')
    ];
  };
}
