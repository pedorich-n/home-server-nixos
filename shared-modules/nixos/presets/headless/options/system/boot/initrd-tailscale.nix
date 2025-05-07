{ config, lib, pkgs, ... }:
let
  cfg = config.custom.boot.initrd.network.tailscale;
in
{
  options = {
    custom.boot.initrd.network.tailscale = {
      enable = lib.mkEnableOption "Initrd Tailscale";

      package = lib.mkPackageOption pkgs "tailscale" { };

      authKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/run/secrets/tailscale_key";
        description = ''
          A file containing the auth key.
          Tailscale will be automatically started if provided.
        '';
      };

      interfaceName = lib.mkOption {
        type = lib.types.str;
        default = "tailscale0";
        description = ''The interface name for tunnel traffic. Use "userspace-networking" (beta) to not use TUN.'';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 41641;
        description = "The port to listen on for tunnel traffic (0=autoselect).";
      };
    };
  };

  # A combination of 
  # https://github.com/ElvishJerricco/stage1-tpm-tailscale/blob/2c07f2a531e1557965a0d483ea694fabf9a6d5bb/initrd-tailscale.nix and
  # https://github.com/NixOS/nixpkgs/blob/6739a5d2bf8eb57e3d785101e47496978a3b1835/nixos/modules/services/networking/tailscale.nix and
  # https://github.com/yomaq/nix-config/blob/f89a171ec539b5eef726155ea4b7088fe9afae84/modules/hosts/initrd-tailscale/nixos.nix#L144
  config = lib.mkIf cfg.enable {
    boot.initrd = {
      kernelModules = [
        "tun"
      ];

      secrets = {
        "/etc/tailscale/auth_key" = cfg.authKeyFile;
      };

      systemd = {
        initrdBin = [
          cfg.package
          pkgs.iproute2
          pkgs.iptables
          pkgs.iputils
        ];
        packages = [
          cfg.package
          pkgs.jq
        ];

        network.networks."50-tailscale" = {
          matchConfig = {
            Name = cfg.interfaceName;
          };
          linkConfig = {
            Unmanaged = true;
            ActivationPolicy = "manual";
          };
        };

        services = {
          tailscaled = {
            wantedBy = [ "initrd.target" ];
            after = [ "network.target" ];

            serviceConfig.Environment = [
              "PORT=${builtins.toString cfg.port}"
              ''"FLAGS=--tun ${lib.escapeShellArg cfg.interfaceName}"''
            ];
          };

          tailscaled-autoconnect = {
            wantedBy = [ "initrd.target" ];
            wants = [ "tailscaled.service" ];
            after = [
              "tailscaled.service"
              "initrd-nixos-copy-secrets.service"
            ];

            serviceConfig = {
              Type = "oneshot";
            };

            path = [
              pkgs.jq
            ];

            script =
              let
                statusCommand = "${lib.getExe' cfg.package "tailscale"} status --json --peers=false | jq -r '.BackendState'";
              in
              ''
                while [[ "$(${statusCommand})" == "NoState" ]]; do
                  sleep 0.5
                done
                status=$(${statusCommand})
                if [[ "$status" == "NeedsLogin" || "$status" == "NeedsMachineAuth" ]]; then
                  ${lib.getExe' cfg.package "tailscale"} up --auth-key "file:/etc/tailscale/auth_key" --hostname "${config.networking.hostName}-initrd"
                fi
              '';
          };
        };
      };
    };
  };
}
