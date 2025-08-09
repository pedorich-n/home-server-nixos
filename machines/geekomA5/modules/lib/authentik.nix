{ networkingLib, ... }:
{
  _module.args.authentikLib = {
    mkIssuerUrl = application: "${networkingLib.mkUrl "authentik"}/application/o/${application}/.well-known/openid-configuration";
  };
}
