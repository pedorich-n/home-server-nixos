{ config, ... }:
{
  _module.args.networkingLib = rec {
    mkDomain = service: "${service}.${config.custom.networking.domain}";

    mkTunneledDomain = service: "${service}.${config.custom.networking.tunneledDomain}";

    mkCustomUrl =
      {
        scheme ? "https",
        service,
        domainFromService ? mkDomain,
      }:
      "${scheme}://${domainFromService service}";

    mkUrl = service: mkCustomUrl { inherit service; };

    mkTunneledUrl =
      service:
      mkCustomUrl {
        inherit service;
        domainFromService = mkTunneledDomain;
      };
  };
}
