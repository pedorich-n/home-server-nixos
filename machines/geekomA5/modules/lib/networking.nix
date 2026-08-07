{
  config,
  ...
}:
{
  _module.args.networkingLib = rec {
    mkDomain = service: "${service}.${config.custom.networking.domain}";
    mkLocalDomain = service: "${service}.${config.custom.networking.localDomain}";

    mkCustomUrl =
      {
        scheme ? "https",
        service,
        domainFromService ? mkLocalDomain,
        port ? null,
      }:
      "${scheme}://${domainFromService service}${if port != null then ":${builtins.toString port}" else ""}";

    mkLocalUrl = service: mkCustomUrl { inherit service; };

    mkUrl =
      service:
      mkCustomUrl {
        inherit service;
        domainFromService = mkDomain;
      };
  };
}
