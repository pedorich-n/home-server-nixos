{
  config,
  networkingLib,
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

    services.caddy.hosts.searxng-mcp = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
    };
  };

  services.mcp-searxng = {
    enable = true;

    searxngUrl = networkingLib.mkLocalUrl "searxng";

    environment = {
      MCP_HTTP_HOST = "127.0.0.1";
      MCP_HTTP_PORT = portsCfg.port;
    };
  };

}
