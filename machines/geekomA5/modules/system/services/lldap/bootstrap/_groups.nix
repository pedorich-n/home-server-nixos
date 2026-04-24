{
  runCommand,
  lib,
}:
let
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
