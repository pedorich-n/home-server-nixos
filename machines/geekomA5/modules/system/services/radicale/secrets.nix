{
  autheliaLib,
  config,
  pkgs,
  lib,
  ...
}:
let
  service = config.sops.placeholder."lldap/users/service_radicale_holidays/username";

  # Column order and names of Radicale's CSV sharing database.
  # See https://github.com/Kozea/Radicale/blob/c23d6759c70bfa5554b2baeaa01df83ea51bafc7/SHARING.md
  fields = [
    "ShareType"
    "PathOrToken"
    "PathMapped"
    "Conversion"
    "Owner"
    "User"
    "Permissions"
    "EnabledByOwner"
    "EnabledByUser"
    "HiddenByOwner"
    "HiddenByUser"
    "TimestampCreated"
    "TimestampUpdated"
    "Properties"
    "Actions"
  ];

  mkShare = uuid: name: {
    ShareType = "map";
    PathOrToken = "/{user}/${name}/";
    PathMapped = "/${service}/${uuid}/";
    Conversion = "none";
    Owner = service;
    User = ":${autheliaLib.groups.Users}";
    Permissions = "r";
    EnabledByOwner = "true";
    EnabledByUser = "true";
    HiddenByOwner = "false";
    HiddenByUser = "false";
    TimestampCreated = "0";
    TimestampUpdated = "0";
    Properties = "";
    Actions = "";
  };

  rows = [
    (mkShare "f74b3d44-af0c-df44-39eb-a2e4dd0dded4" "holidays-japan")
    (mkShare "657d386c-1325-026a-87c8-624e9e4a3fc7" "holidays-ukraine")
  ];

  ssvLine = values: lib.concatStringsSep ";" values;

  renderRow = row: ssvLine (map (field: row.${field}) fields);
in
{
  sops.templates."radicale/sharing.csv" = {
    file = pkgs.writeText "radicale-sharing.csv" (lib.concatLines ([ (ssvLine fields) ] ++ map renderRow rows));
    restartUnits = [
      config.systemd.services.radicale.name
    ];
  };
}
