{ lib, config, ... }:
with lib;
let
  cfg = config.custom.shared-config;

  portItemSubmodule = types.submodule {
    options = {
      port = mkOption {
        type = types.port;
      };
      openFirewall = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  portsSubmodule = types.submodule {
    options = {
      tcp = mkOption {
        type = types.attrsOf portItemSubmodule;
        default = { };
      };

      udp = mkOption {
        type = types.attrsOf portItemSubmodule;
        default = { };
      };
    };
  };


  getFirewallPorts = ports: type:
    let
      foldPortsToList = ports: type: attrsets.foldlAttrs (acc: _: portItem: acc ++ (builtins.attrValues portItem.${type})) [ ] ports;
      filterFirewallPorts = ports: builtins.filter (portItem: portItem.openFirewall) ports;
      mapPortItemToInt = ports: builtins.map (portItem: portItem.port) ports;
    in
    mapPortItemToInt (filterFirewallPorts (foldPortsToList ports type));

in
{
  ###### interface
  options = {
    custom.shared-config = {
      ports = mkOption {
        type = types.attrsOf portsSubmodule;
        default = { };
      };
    };
  };

  ###### implementation
  config = {
    networking.firewall = {
      allowedTCPPorts = getFirewallPorts cfg.ports "tcp";
      allowedUDPPorts = getFirewallPorts cfg.ports "udp";
    };
  };
}
