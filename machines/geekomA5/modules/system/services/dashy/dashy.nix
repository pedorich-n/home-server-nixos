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

  custom.services.caddy.hosts = {
    dashy = {
      kind = "static";
      root = dashy-static;
      extraConfig = ''
        encode gzip zstd
      '';
    };

    # Top-level domain redirect: bare domain → dashy.
    "${config.custom.networking.localDomain}" = {
      kind = "redirect";
      domain = config.custom.networking.localDomain;
      target = networkingLib.mkLocalUrl "dashy";
    };
  };

}
