{
  config,
  networkingLib,
  pkgs,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.dashy;

  dashy-static = pkgs.callPackage ./_dashy-static.nix { inherit networkingLib; };
in
{
  custom.networking.ports.tcp.dashy = {
    port = 48000;
    openFirewall = false;
  };

  services = {
    static-web-server = {
      enable = true;

      listen = "127.0.0.1:${portsCfg.portStr}";
      root = dashy-static;
    };

    traefik.dynamicConfigOptions.http = {
      routers.dashy-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "dashy"}`)";
        service = "dashy-secure";
      };

      services.dashy-secure = {
        loadBalancer.servers = [ { url = "http://127.0.0.1:${portsCfg.portStr}"; } ];
      };
    };
  };

}
