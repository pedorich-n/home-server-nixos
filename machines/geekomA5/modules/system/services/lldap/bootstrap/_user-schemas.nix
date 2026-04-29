{
  writers,
}:
let
  schemas = [
    {
      name = "sshpubkey";
      attributeType = "STRING";
      isEditable = true;
      isList = true;
      isVisible = true;
    }
  ];
in
writers.writeJSON "ldap-user-schemas.json" schemas
