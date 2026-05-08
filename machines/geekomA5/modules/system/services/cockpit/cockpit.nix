{
  config,
  networkingLib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  package = pkgs-unstable.cockpit;

  portCfg = config.custom.networking.ports.tcp.cockpit-root;
in
{
  custom = {
    networking.ports.tcp = {
      cockpit-root = {
        port = 30700;
        openFirewall = false;
      };
      cockpit = {
        port = 45090;
        openFirewall = false;
      };
    };

    services.caddy.hosts.cockpit = {
      upstream = "http://127.0.0.1:${portCfg.portStr}";
      auth = "authelia";
    };
  };

  #LINK - pkgs/nixos/cockpit-plugins/files.nix
  #LINK - pkgs/nixos/cockpit-plugins/podman.nix
  environment.systemPackages = [
    pkgs.cockpit-plugins.files
    pkgs.cockpit-plugins.podman
  ];

  # Run a dedicated session as root to avoid login screen and use external tool for access management
  # See https://github.com/cockpit-project/cockpit/discussions/20814#discussioncomment-10542120
  # See https://github.com/rhinstaller/anaconda-webui/blob/4904f91cd5d84143460a11612032ff315f9563b0/src/systemd/webui-cockpit-ws.service
  systemd.services."cockpit-root" = {
    description = "Cockpit Web Session for root";
    after = [
      "network.target"
    ];
    wantedBy = [
      "multi-user.target"
    ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${package}/libexec/cockpit-ws --for-tls-proxy --port=${portCfg.portStr} --address=127.0.0.1 --local-session=${package}/bin/cockpit-bridge";
      Restart = "on-failure";
      PAMName = "cockpit";
    };
  };

  services = {
    cockpit = {
      enable = true;
      inherit package;

      inherit (config.custom.networking.ports.tcp.cockpit) port openFirewall;

      allowed-origins = [
        (networkingLib.mkUrl "cockpit")
        (networkingLib.mkCustomUrl {
          scheme = "wss";
          service = "cockpit";
        })

      ];

      settings = {
        WebService = {
          ProtocolHeader = "X-Forwarded-Proto";
          ForwardedForHeader = "X-Forwarded-For";
          AllowUnencrypted = true;
        };
      };
    };

  };

}
