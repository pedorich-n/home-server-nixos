{
  networkingLib,
  ...
}:
{
  _module.args.autheliaLib = {
    issuerUrl = networkingLib.mkLocalUrl "authelia";
    discoveryUrl = "${networkingLib.mkLocalUrl "authelia"}/.well-known/openid-configuration";

    # Should be the same as
    #LINK - machines/geekomA5/modules/system/services/lldap/bootstrap/_groups.nix
    groups = {
      Admins = "Admins";
      Users = "Users";
      Service = "Service";
    };
  };
}
