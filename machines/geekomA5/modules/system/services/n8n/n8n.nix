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

  package = pkgs-unstable.n8n;
  node = lib.findFirst (d: d.pname == "nodejs") null package.buildInputs;
in
{
  disabledModules = [ "services/misc/n8n.nix" ];
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/n8n.nix" ];

  assertions = [
    {
      assertion = node != null;
      message = "Failed to find nodejs in n8n's build inputs!";
    }
  ];

  custom = {
    networking.ports.tcp.n8n = {
      port = 30100;
      openFirewall = false;
    };

    services.caddy.hosts.n8n = {
      upstream = "http://localhost:${portsCfg.portStr}";
    };
  };

  systemd.services.n8n = {
    # This allows n8n to install community nodes using `npm`
    path = [
      node
      pkgs.gnutar
      pkgs.gzip
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
        WEBHOOK_URL = networkingLib.mkTunneledUrl "n8n";

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
