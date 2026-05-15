{
  inputs,
  config,
  networkingLib,
  pkgs-unstable,
  lib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;
in
{
  disabledModules = [ "services/web-servers/caddy/default.nix" ];
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/web-servers/caddy/default.nix" ];

  custom.networking.ports.tcp = {
    caddy-admin = {
      port = 2019;
      openFirewall = false; # Caddy admin API should not be exposed to the network
    };
    caddy-http = {
      port = 80;
      openFirewall = true;
    };
    caddy-https = {
      port = 443;
      openFirewall = true;
    };
    caddy-metrics = {
      port = 9200;
      openFirewall = false;
    };
  };

  systemd.services.caddy = {
    serviceConfig.SupplementaryGroups = [
      config.security.acme.certs.local.group
    ];
  };

  services.caddy = {
    enable = true;

    httpPort = portsCfg.caddy-http.port;
    httpsPort = portsCfg.caddy-https.port;

    logFormat = ''
      output stderr
      format console
      level INFO
    '';

    # mkBefore so that the snippet is included before any virtual host configs
    extraConfig = lib.mkBefore ''
      (error-handler) {
        handle_errors {
          root * ${pkgs-unstable.error-pages}/share/error-pages/app-down
          rewrite * /{err.status_code}.html
          file_server
        }
      }
    '';

    # Top-level catch-all for unmatched hosts to serve the error page.
    virtualHosts."${networkingLib.mkDomain "*"}" = {
      useACMEHost = "local";
      logFormat = null; # Disable access logs
      extraConfig = ''
        import error-handler

        error * 404  # Trigger 404 error to invoke handle_errors
      '';
    };
  };
}
