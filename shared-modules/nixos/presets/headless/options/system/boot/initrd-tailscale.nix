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

      availableKernelModules = [
        "ip_tables"
        "iptable_filter"
        "iptable_nat"
        "nf_conntrack"
        "nf_nat"
        "xt_mark"
        "nft_chain_nat"
        "nft_compat"
        "x_tables"
        "xt_LOG"
        "xt_MASQUERADE"
        "xt_addrtype"
        "xt_comment"
        "xt_conntrack"
        "xt_multiport"
        "xt_pkttype"
        "xt_tcpudp"
      ];

      secrets = {
        "/etc/tailscale/auth_key" = cfg.authKeyFile;
      };

      systemd = {
        # Packages listed here will be included in initrd's /bin
        initrdBin = with pkgs; [
          cfg.package

          jq

          iproute2
          iptables
          iputils
        ];

        storePaths = [
          "${pkgs.glibc}/lib/libresolv.so.2"
          "${pkgs.glibc}/lib/libnss_dns.so.2"
        ];

        network = {
          # I don't want to stall boot if Tailscale can't connect.
          wait-online.ignoredInterfaces = [
            cfg.interfaceName
          ];

          networks."50-tailscale" = {
            matchConfig = {
              Name = cfg.interfaceName;
            };
            linkConfig = {
              Unmanaged = true;
              ActivationPolicy = "manual";
            };
          };
        };

        services = {
          tailscaled = {
            wantedBy = [ "initrd.target" ];
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            before = [ "shutdown.target" ];
            conflicts = [ "shutdown.target" ];

            serviceConfig = {
              Type = "notify";
              ExecStart = ''
                ${lib.getExe' cfg.package "tailscaled"} --state=mem: --tun=${lib.escapeShellArg cfg.interfaceName}
              '';
              ExecStopPost = "${lib.getExe' cfg.package "tailscaled"} --cleanup";

              RuntimeDirectory = "tailscale";
              RuntimeDirectoryMode = 0755;
            };
          };

          tailscaled-autoconnect = {
            wantedBy = [ "initrd.target" ];
            wants = [ "tailscaled.service" ];
            after = [
              "tailscaled.service"
              "initrd-nixos-copy-secrets.service"
            ];
            before = [ "shutdown.target" ];
            conflicts = [ "shutdown.target" ];

            serviceConfig = {
              Type = "oneshot";
            };

            script =
              let
                statusCommand = "${lib.getExe' cfg.package "tailscale"} status --json --peers=false | ${lib.getExe pkgs.jq} -r '.BackendState'";
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
