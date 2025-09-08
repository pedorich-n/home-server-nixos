{
  config,
  ...
}:
{
  custom.networking.ports.tcp.mosquitto = {
    port = 1883;
    openFirewall = true;
  };

  services.mosquitto = {
    enable = true;

    persistence = true;

    logDest = [ "stdout" ];

    listeners = [
      {
        port = config.custom.networking.ports.tcp.mosquitto.port;
        users = {
          iot-device = {
            hashedPasswordFile = config.sops.secrets."mosquitto/users/iot-device/password".path;
            acl = [ "readwrite #" ];
          };
          homeassistant = {
            hashedPasswordFile = config.sops.secrets."mosquitto/users/homeassistant/password".path;
            acl = [ "readwrite #" ];
          };
          zigbee2mqtt = {
            hashedPasswordFile = config.sops.secrets."mosquitto/users/zigbee2mqtt/password".path;
            acl = [ "readwrite #" ];
          };
          observer = {
            hashedPasswordFile = config.sops.secrets."mosquitto/users/observer/password".path;
            acl = [ "read #" ];
          };
        };
      }
    ];
  };
}
