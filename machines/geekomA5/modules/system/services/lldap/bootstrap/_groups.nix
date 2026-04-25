{
  runCommand,
  lib,
}:
let
  # Should be the same as
  #LINK - machines/geekomA5/modules/system/services/authelia/_shared.nix
  groups = [
    "Users"
    "Admins"
    "Service"
  ];
in
runCommand "generate-ldap-groups" { } ''
  mkdir -p $out

  ${lib.concatStringsSep "\n" (map (group: "echo '${builtins.toJSON { name = group; }}' > $out/${group}.json") groups)}
''
