{
  config,
  ...
}:
{
  _module.args.networkingLib = rec {
    mkDomain = service: "${service}.${config.custom.networking.domain}";

    mkTunneledDomain = service: "${service}.${config.custom.networking.tunneledDomain}";

    mkCustomUrl =
      {
        scheme ? "https",
        service,
        domainFromService ? mkDomain,
        port ? null,
      }:
      "${scheme}://${domainFromService service}${if port != null then ":${builtins.toString port}" else ""}";

    mkUrl = service: mkCustomUrl { inherit service; };

    mkTunneledUrl =
      service:
      mkCustomUrl {
        inherit service;
        domainFromService = mkTunneledDomain;
      };
  };
}
