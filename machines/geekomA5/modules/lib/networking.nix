{ config, ... }: {
  _module.args.networkingLib = rec {
    mkDomain = service: "${service}.${config.custom.networking.domain}";

    mkCustomUrl = { scheme ? "https", service }: "${scheme}://${mkDomain service}";
    mkUrl = service: mkCustomUrl { inherit service; };
  };
}
