{
  tmpfilesLib,
  ...
}:
{
  systemd.tmpfiles.settings."90-zigbee2mqtt" = {
    "/mnt/store/home-automation/zigbee2mqtt-old/configuration.yaml" = {
      "C+" = tmpfilesLib.mkDefaultTmpFile "${./configuration.yaml}";
    };
  };
}
