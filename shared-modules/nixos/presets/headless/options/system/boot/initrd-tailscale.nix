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

      extraUpFlags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "--ssh" ];
        description = ''
          Extra flags to pass to {command}`tailscale up`. Only applied if `authKeyFile` is specified.";
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd = {
      availableKernelModules = [
        "tun"
      ];

      systemd.services = { };
    };
  };
}
