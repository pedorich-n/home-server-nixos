{ inputs, lib, ... }:
let
  root = "${inputs.home-server-nixos-secrets}/plaintext/rendered";
in
{
  options = {
    custom.secrets.plaintext = {
      variables = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
        readOnly = true;
        default = import "${root}/variables.nix";
      };
    };
  };
}
