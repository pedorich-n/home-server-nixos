{
  config,
  networkingLib,
  ...
}:
let
  portCfg = config.custom.networking.ports.tcp.gitea-mirror;
in
{
  custom.networking.ports.tcp.gitea-mirror = {
    port = 45101;
    openFirewall = false;
  };

  services = {
    gitea-mirror = {
      enable = true;
      inherit (portCfg) port openFirewall;

      betterAuthUrl = networkingLib.mkUrl "gitea-mirror";
      betterAuthTrustedOrigins = networkingLib.mkUrl "gitea-mirror";

      environmentFile = config.sops.secrets."gitea-mirror/main.env".path;
    };

    traefik.dynamicConfigOptions.http = {
      routers.gitea-mirror = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "gitea-mirror"}`)";
        service = "gitea-mirror-secure";
      };

      services.gitea-mirror-secure = {
        loadBalancer.servers = [ { url = "http://localhost:${portCfg.portStr}"; } ];
      };
    };
  };
}
