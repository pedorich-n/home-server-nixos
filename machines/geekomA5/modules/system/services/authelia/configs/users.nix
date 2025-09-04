{
  config,
  pkgs,
  lib,
  ...
}:
let
  shared = import ../_shared.nix;

  yamlFormat = pkgs.formats.yaml { };
in
{
  sops.templates."authelia/users.yaml" = {
    owner = config.services.authelia.instances.main.user;
    group = config.services.authelia.instances.main.group;

    file = yamlFormat.generate "authelia-users-template.yaml" {
      users = {
        ${config.sops.placeholder."authelia/users/user_1/username"} = {
          displayname = config.sops.placeholder."authelia/users/user_1/username";
          email = config.sops.placeholder."authelia/users/user_1/email";
          password = config.sops.placeholder."authelia/users/user_1/password";
          groups = lib.attrValues shared.groups;
        };
      };
    };
  };
}
