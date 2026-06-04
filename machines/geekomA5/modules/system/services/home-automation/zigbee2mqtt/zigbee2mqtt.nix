{
  config,
  networkingLib,
  systemdLib,
  lib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;

  z2mSecrets = config.sops.secrets."home-automation/zigbee2mqtt_secrets.yaml".path;
in
{
  custom = {
    networking.ports.tcp.zigbee2mqtt = {
      port = 30300;
      openFirewall = false;
    };

    services.caddy.hosts.zigbee2mqtt = {
      upstream = "http://127.0.0.1:${portsCfg.zigbee2mqtt.portStr}";
      auth = "authelia";
    };

  };

  systemd.services.zigbee2mqtt = {
    unitConfig = lib.mkMerge [
      (systemdLib.requiresAfter [ config.systemd.services.mosquitto.name ])
      (systemdLib.bindsToAfter [ "dev-ttyZigbee.device" ])
    ];

    serviceConfig = {
      SupplementaryGroups = [
        config.users.groups.zigbee.name
      ];
      ReadOnlyPaths = [
        z2mSecrets
      ];
    };
  };

  services.zigbee2mqtt = {
    enable = true;
    dataDir = "/mnt/store/home-automation/zigbee2mqtt";

    settings = {
      homeassistant = {
        enabled = true;
      };

      availability = {
        enabled = true;
      };

      mqtt = {
        base_topic = "zigbee2mqtt";
        server = "mqtt://127.0.0.1:${portsCfg.mosquitto.portStr}";
        keepalive = 60;
        user = "!${z2mSecrets} mqtt_user";
        password = "!${z2mSecrets} mqtt_password";
        reject_unauthorized = true;
      };

      serial = {
        port = "/dev/ttyZigbee";
        adapter = "zstack";
      };

      frontend = {
        enabled = true;
        host = "127.0.0.1";
        port = portsCfg.zigbee2mqtt.port;
        url = networkingLib.mkUrl "zigbee2mqtt";
      };

      advanced = {
        network_key = "!${z2mSecrets} network_key";
        log_level = "error";
        log_output = [
          "console"
        ];
        channel = 25;
        last_seen = "ISO_8601";
      };
    };
  };
}
