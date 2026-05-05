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
      openFirewall = false;
    };
    caddy-http = {
      port = 8181;
      openFirewall = true;
    };
    caddy-https = {
      port = 8443;
      openFirewall = true;
    };
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
