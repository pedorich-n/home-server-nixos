{
  networkingLib,
  ...
}:
{
  _module.args.autheliaLib = {
    issuerUrl = networkingLib.mkUrl "authelia";
    discoveryUrl = "${networkingLib.mkUrl "authelia"}/.well-known/openid-configuration";
  };
}
