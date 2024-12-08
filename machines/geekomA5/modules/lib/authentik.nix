{ config, ... }: {
  _module.args.authentikLib = {
    mkIssuerUrl = application: "http://authentik.${config.custom.networking.domain}/application/o/${application}/.well-known/openid-configuration";

    openIdScopes = ''"openid profile email"'';
  };
}
