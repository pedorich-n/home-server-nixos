{ lib, config, ... }:
let
  cfg = config.custom.networking.ports;

  portItemSubmodule = with lib; types.submodule ({ config, ... }: {
    options = {
      port = mkOption {
        type = types.port;
      };
      portStr = mkOption {
        type = types.str;
        readOnly = true;
      };
      openFirewall = mkOption {
        type = types.bool;
        default = false;
      };
    };

    config = {
      portStr = builtins.toString config.port;
    };
  });

  getFirewallPorts = ports: lib.pipe ports [
    builtins.attrValues
    (builtins.filter (item: item.openFirewall))
    (builtins.map (item: item.port))
  ];

  assertUniquePorts = ports:
    let
      strPort = item: "${builtins.toString item.port}";
      groupedByPort = lib.foldlAttrs (acc: name: item: acc // { ${strPort item} = (acc.${strPort item} or [ ]) ++ [ name ]; }) { } ports;

      mkErrorMsg = port: names: ''Multiple definitions are trying to bind to port ${port}: ${builtins.concatStringsSep ", " names}'';
      assertions = lib.mapAttrsToList (port: names: { assertion = (builtins.length names) == 1; message = mkErrorMsg port names; }) groupedByPort;
    in
    assertions;
in
{
  ###### interface
  options = with lib; {
    custom.networking.ports = {
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

  ###### implementation
  config = {
    assertions = (assertUniquePorts cfg.tcp) ++ (assertUniquePorts cfg.udp);

    networking.firewall = {
      allowedTCPPorts = getFirewallPorts cfg.tcp;
      allowedUDPPorts = getFirewallPorts cfg.udp;
    };
  };
}
