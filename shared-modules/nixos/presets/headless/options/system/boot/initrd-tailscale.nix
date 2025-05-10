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
        '';
      };

      interfaceName = lib.mkOption {
        type = lib.types.str;
        default = "tailscale0";
        description = ''
          The interface name for tunnel traffic
        '';
      };

      extraDaemonFlags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "--no-logs-no-support" ];
        description = ''
          Extra flags to pass to {command}`tailscaled`.
        '';
      };

      extraUpFlags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "--ssh" ];
        description = ''
          Extra flags to pass to {command}`tailscale up`.
        '';
      };
    };
  };

  # A combination of 
  # https://github.com/ElvishJerricco/stage1-tpm-tailscale/blob/2c07f2a531e1557965a0d483ea694fabf9a6d5bb/initrd-tailscale.nix and
  # https://github.com/yomaq/nix-config/blob/f89a171ec539b5eef726155ea4b7088fe9afae84/modules/hosts/initrd-tailscale/nixos.nix and
  # https://github.com/NixOS/nixpkgs/blob/6739a5d2bf8eb57e3d785101e47496978a3b1835/nixos/modules/services/networking/tailscale.nix
  config = lib.mkIf cfg.enable {
    boot.initrd = {
      kernelModules = [
        "tun"
      ];

      availableKernelModules = [
        "ip_tables"
        "nf_conntrack"
        "nf_nat"
        "nft_chain_nat"
        "nft_compat"
        "x_tables"
        "xt_mark"
        "xt_MASQUERADE"
        "xt_tcpudp"
        "wireguard"
      ];

      secrets = {
        "/etc/tailscale/auth_key" = cfg.authKeyFile;
      };

      systemd = {
        # Packages listed here will be included in initrd's `/bin` by combining their `/bin` outputs into a single folder
        initrdBin = with pkgs; [
          cfg.package

          jq

          getent
          iproute2
          iptables
          iputils
        ];

        # Paths listed here will be copied to initrd's `/nix/store`
        storePaths = [
          "${pkgs.iptables}/lib"
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
          # Mostly copied from https://github.com/tailscale/tailscale/blob/cb6fc37d660f4/cmd/tailscaled/tailscaled.service
          tailscaled = {
            wantedBy = [ "initrd.target" ];
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            before = [ "shutdown.target" ];
            conflicts = [ "shutdown.target" ];

            serviceConfig = {
              Type = "notify";

              # See https://github.com/tailscale/tailscale/issues/13200#issuecomment-2351633313 for --statedir
              ExecStart = ''
                ${lib.getExe' cfg.package "tailscaled"} \
                  --tun=${lib.escapeShellArg cfg.interfaceName} \
                  --state=mem: \
                  --statedir="/var/lib/tailscale/" \
                  ${lib.escapeShellArgs cfg.extraDaemonFlags}
              '';
              ExecStopPost = "${lib.getExe' cfg.package "tailscaled"} --cleanup";

              RuntimeDirectory = "tailscale";
              RuntimeDirectoryMode = 0755;
              StateDirectory = "tailscale";
              StateDirectoryMode = 0700;
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

            serviceConfig.Type = "oneshot";

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
                  ${lib.getExe' cfg.package "tailscale"} up \
                    --auth-key "file:/etc/tailscale/auth_key" \
                    --hostname "${config.networking.hostName}-initrd" \
                    ${lib.escapeShellArgs cfg.extraUpFlags}
                fi
              '';
          };
        };
      };
    };
  };
}
