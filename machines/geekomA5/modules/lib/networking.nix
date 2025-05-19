{ config, ... }: {
  _module.args.networkingLib = rec {
    mkDomain = service: "${service}.${config.custom.networking.domain}";
    mkExternalDomain = service: "${service}.${config.custom.networking.domain-external}";

    mkUrl = { scheme ? "http", service, domain }: "${scheme}://${service}.${domain}";
    mkInternalUrl = service: mkUrl { inherit service; inherit (config.custom.networking) domain; };
    mkExternalUrl = service: mkUrl {
      inherit service;
      domain = config.custom.networking.domain-external;
      scheme = "https";
    };
  };
}
