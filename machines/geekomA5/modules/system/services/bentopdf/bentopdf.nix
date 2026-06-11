{
  networkingLib,
  ...
}:
{
  services.bentopdf = {
    enable = true;
    domain = networkingLib.mkDomain "bentopdf";

    caddy = {
      enable = true;
      virtualHost = {
        logFormat = null; # Disable access logs
        useACMEHost = "local";
        extraConfig = ''
          import error-handler
        '';
      };
    };
  };
}
