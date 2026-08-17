{
  config,
  autheliaLib,
  networkingLib,
  pkgs-unstable,
  ...
}:
let
  dashy-static = pkgs-unstable.callPackage ./_dashy-static.nix {
    inherit networkingLib autheliaLib;
  };
in
{
  custom = {
    networking.ports.tcp.dashy = {
      port = 30000;
      openFirewall = false;
    };
  };

  services = {
    caddy.virtualHosts = {
      "dashy.${config.custom.networking.localDomain}" = {
        useACMEHost = "local";
        logFormat = null; # Disable access logs
        extraConfig = ''
          root * ${dashy-static}
          encode gzip zstd
          file_server

          import error-handler
        '';
      };

      # Top-level domain redirect: bare domain → dashy.
      "${config.custom.networking.localDomain}" = {
        useACMEHost = "local";
        logFormat = null; # Disable access logs
        extraConfig = "redir ${networkingLib.mkLocalUrl "dashy"}{uri} permanent";
      };
    };

  };

}
