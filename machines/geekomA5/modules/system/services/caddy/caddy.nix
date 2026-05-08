{
  inputs,
  config,
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
  };
}
