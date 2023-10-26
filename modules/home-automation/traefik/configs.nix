{ pkgs, ... }:
let
  generateYaml = filename: content: (pkgs.formats.yaml { }).generate filename content;

  staticConfigContent = {
    api = {
      dashboard = true;
      insecure = true;
    };

    providers = {
      file = {
        filename = "/config/dynamic.yaml";
        watch = true;
      };
    };

    entryPoints = {
      web.address = ":80";
      # ha.address = ":8123";
    };
  };

  dynamicConfigContent = {
    http = {
      routers = {
        homeassistant = {
          entryPoints = [ "web" ];
          rule = "Host(`homeassistant.server.local`)";
          service = "homeassistant";
        };
        nodered = {
          entryPoints = [ "web" ];
          rule = "Host(`nodered.server.local`)";
          service = "nodered";
        };
        traefik = {
          entryPoints = [ "web" ];
          rule = "Host(`traefik.server.local`)";
          service = "traefik";
        };
        zigbee2mqtt = {
          entryPoints = [ "web" ];
          rule = "Host(`zigbee2mqtt.server.local`)";
          service = "zigbee2mqtt";
        };
        whatsupdocker = {
          entryPoints = [ "web" ];
          rule = "Host(`whatsupdocker.server.local`)";
          service = "whatsupdocker";
        };
        portainer = {
          entryPoints = [ "web" ];
          rule = "Host(`portainer.server.local`)";
          service = "portainer";
        };
        homer = {
          entryPoints = [ "web" ];
          rule = "Host(`server.local`)";
          service = "homer";
        };
        glances = {
          entryPoints = [ "web" ];
          rule = "Host(`glances.server.local`)";
          service = "glances";
        };
        netdata = {
          entryPoints = [ "web" ];
          rule = "Host(`netdata.server.local`)";
          service = "netdata";
        };
      };
      services = {
        homeassistant = {
          loadBalancer = {
            servers = [{ url = "http://homeassistant:80"; }];
          };
        };
        nodered = {
          loadBalancer = {
            servers = [{ url = "http://nodered:1880"; }];
          };
        };
        traefik = {
          loadBalancer = {
            servers = [{ url = "http://traefik:8080"; }];
          };
        };
        zigbee2mqtt = {
          loadBalancer = {
            servers = [{ url = "http://zigbee2mqtt:8080"; }];
          };
        };
        whatsupdocker = {
          loadBalancer = {
            servers = [{ url = "http://whatsupdocker:3000"; }];
          };
        };
        portainer = {
          loadBalancer = {
            servers = [{ url = "http://portainer:9000"; }];
          };
        };
        homer = {
          loadBalancer = {
            servers = [{ url = "http://homer:8080"; }];
          };
        };
        glances = {
          loadBalancer = {
            servers = [{ url = "http://glances:61208"; }];
          };
        };
        netdata = {
          loadBalancer = {
            servers = [{ url = "http://netdata:19999"; }];
          };
        };
      };
    };
  };

in
{
  static = generateYaml "traefik-static.yaml" staticConfigContent;
  dynamic = generateYaml "traefik-dynamic.yaml" dynamicConfigContent;
}
