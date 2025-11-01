{ config, networkingLib, ... }:
let
  portsCfg = config.custom.networking.ports.tcp.ollama;
in
{
  custom.networking.ports.tcp.ollama = {
    port = 11434;
    openFirewall = false;
  };

  systemd.services = {
    ollama.serviceConfig.SupplementaryGroups = [
      config.users.groups.users.name
    ];

    ollama-model-loader.serviceConfig.SupplementaryGroups = [
      config.users.groups.users.name
    ];
  };

  services = {
    ollama = {
      enable = true;
      acceleration = false; # This machine only has an integrated GPU that Ollama doesn't support

      host = "0.0.0.0";
      inherit (portsCfg) port;

      home = "/mnt/store/ollama";

      loadModels = [
        "qwen3:8b"
      ];
    };

    traefik.dynamicConfigOptions.http = {
      routers.ollama-secure = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "ollama"}`)";
        service = "ollama-secure";
      };

      services.ollama-secure = {
        loadBalancer.servers = [ { url = "http://localhost:${portsCfg.portStr}"; } ];
      };
    };
  };
}
