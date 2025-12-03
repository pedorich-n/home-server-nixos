{ networkingLib, ... }:
let
  autheliaUrl = networkingLib.mkUrl "authelia";
in
{
  _module.args.autheliaLib = {
    issuerUrl = "${autheliaUrl}/.well-known/openid-configuration";

    authorizationUrl = "${autheliaUrl}/api/oidc/authorization";
    tokenUrl = "${autheliaUrl}/api/oidc/token";
    userInfoUrl = "${autheliaUrl}/api/oidc/userinfo";
    jwksUrl = "${autheliaUrl}/jwks.json";
  };
}
