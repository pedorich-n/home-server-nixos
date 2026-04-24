{
  formats,
}:
let
  jsonFormat = formats.json { };

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
jsonFormat.generate "ldap-user-schemas.json" schemas
