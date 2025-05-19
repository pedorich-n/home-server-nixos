{ config, networkingLib, ... }: {
  _module.args.authentikLib = {
    mkIssuerUrl = application: "http://authentik.${config.custom.networking.domain}/application/o/${application}/.well-known/openid-configuration";
    mkExternalIssuerUrl = application: "${networkingLib.mkExternalUrl "authentik"}/application/o/${application}/.well-known/openid-configuration";
  };
}
