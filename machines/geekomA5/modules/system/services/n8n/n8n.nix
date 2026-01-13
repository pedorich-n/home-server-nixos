{
  inputs,
  config,
  lib,
  networkingLib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.n8n;

  node = pkgs.nodejs;
  package = pkgs-unstable.n8n.override {
    nodejs = node;
  };
in
{
  disabledModules = [ "services/misc/n8n.nix" ];
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/n8n.nix" ];

  custom.networking.ports.tcp.n8n = {
    port = 5678;
    openFirewall = false;
  };

  systemd.services.n8n = {
    environment = {
      # Since services.n8n.environment is broken, see https://github.com/NixOS/nixpkgs/pull/460609
      N8N_VERSION_NOTIFICATIONS_ENABLED = lib.mkForce "false";
      N8N_DIAGNOSTICS_ENABLED = lib.mkForce "false";
    };

    # This allows n8n to install community nodes using `npm`
    path = with pkgs; [
      node
      gnutar
      gzip
    ];

    serviceConfig = {
      ReadWritePaths = [
        config.custom.manual-backup.root
      ];

      SupplementaryGroups = [
        config.custom.manual-backup.owner.group
      ];
    };
  };

  services = {
    n8n = {
      enable = true;
      inherit (portsCfg) openFirewall;
      inherit package;

      environment = {
        N8N_HOST = networkingLib.mkDomain "n8n";
        N8N_PORT = portsCfg.port;
        N8N_PROTOCOL = "https";
        WEBHOOK_URL = networkingLib.mkUrl "n8n";

        N8N_PROXY_HOPS = "1";

        N8N_RESTRICT_FILE_ACCESS_TO = lib.concatStringsSep ";" [
          config.custom.manual-backup.root
        ];

        NODES_EXCLUDE = "[]";
        N8N_SKIP_AUTH_ON_OAUTH_CALLBACK = "true";

        NODE_ENV = "production";
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.n8n-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "n8n"}`)";
        service = "n8n-secure";
      };

      services.n8n-secure = {
        loadBalancer.servers = [ { url = "http://localhost:${portsCfg.portStr}"; } ];
      };
    };
  };
}
