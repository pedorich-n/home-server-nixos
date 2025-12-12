{
  networkingLib,
  config,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.n8n;
in
{

  custom.networking.ports.tcp.n8n = {
    port = 5678;
    openFirewall = false;
  };

  services = {
    n8n = {
      enable = true;
      inherit (portsCfg) openFirewall;

      environment = {
        N8N_HOST = networkingLib.mkDomain "n8n";
        N8N_PORT = portsCfg.port;
        N8N_PROTOCOL = "https";
        WEBHOOK_URL = networkingLib.mkUrl "n8n";

        # N8N_USER_FOLDER = "/mnt/store/n8n";
        N8N_PROXY_HOPS = "1";

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
