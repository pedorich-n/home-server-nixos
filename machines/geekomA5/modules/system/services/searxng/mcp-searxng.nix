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
