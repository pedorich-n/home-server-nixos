{
  config,
  networkingLib,
  lib,
  pkgs-unstable,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.searxng-mcp;
in
{

  custom = {
    networking.ports.tcp.searxng-mcp = {
      port = 30501;
      openFirewall = false;
    };
  };

  systemd.services.mcp-searxng = {
    description = "SearXNG MCP server (streamable HTTP)";
    after = [
      "network.target"
      "searxng.service"
    ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      SEARXNG_URL = networkingLib.mkLocalUrl "searxng";
      MCP_HTTP_HOST = "127.0.0.1";
      MCP_HTTP_PORT = portsCfg.portStr;

    };

    serviceConfig = {
      ExecStart = lib.getExe pkgs-unstable.mcp-searxng;
      Restart = "on-failure";
      RestartSec = 5;

      # Hardening
      CapabilityBoundingSet = "";
      DynamicUser = true;
      LockPersonality = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
      ];
      UMask = "0077";
    };
  };

}
