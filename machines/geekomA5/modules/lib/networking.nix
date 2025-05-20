{ config, ... }: {
  _module.args.networkingLib = rec {
    mkDomain = service: "${service}.${config.custom.networking.domain}";

    mkUrl = service: "https://${mkDomain service}";
  };
}
