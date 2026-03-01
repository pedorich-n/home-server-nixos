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
  package = pkgs-unstable.n8n.overrideAttrs {
    NODE_OPTIONS = "--max-old-space-size=4096";
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
      # https://github.com/NixOS/nixpkgs/pull/494127 is not yet in unstable
      N8N_RUNNERS_AUTH_TOKEN_FILE = lib.mkForce null;
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

      # https://github.com/NixOS/nixpkgs/pull/494127 is not yet in unstable
      LoadCredential = lib.mkForce [ ];
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

        N8N_SKIP_AUTH_ON_OAUTH_CALLBACK = "true";
        # Yes, they used 3 different separators for multi-value env vars...
        NODES_EXCLUDE = "[]";
        N8N_RESTRICT_FILE_ACCESS_TO = lib.concatStringsSep ";" [
          config.custom.manual-backup.root
        ];
        N8N_DISABLED_MODULES = lib.concatStringsSep "," [
          "chat-hub"
        ];

        # https://github.com/NixOS/nixpkgs/pull/494127 is not yet in unstable
        N8N_RUNNERS_AUTH_TOKEN_FILE = lib.mkForce null;

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
