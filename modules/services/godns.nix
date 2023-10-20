{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.godns;

  generateJson = filename: content: (pkgs.formats.json { }).generate filename content;

  tokenPlaceHolder = "@TOKEN@";
  settings = {
    provider = "DuckDNS";
    login_token = tokenPlaceHolder;
    domains = [{
      domain_name = "www.duckdns.org";
      subdomains = [ "money-guys-play-minecraft" ];
    }];
    interval = 300;
    resolver = "8.8.8.8";
    ip_urls = [
      "https://api.ipify.org"
      "https://api-ipv4.ip.sb/ip"
    ];
    ip_type = "IPv4";
    debug_info = true;
  };

  settingsFile = generateJson "godns.json" settings;
  settingsFileRuntimePath = "/run/godns/godns.json";
in
{
  ###### interface
  options = {
    custom.godns = {
      enable = mkEnableOption "GoDNS service";
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    systemd.services.godns = {
      description = "Dynamic DNS Client";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      preStart = ''
        install --mode=600 --owner=$USER "${settingsFile}" "${settingsFileRuntimePath}"
        "${getExe pkgs.replace-secret}" "${tokenPlaceHolder}" "${config.age.secrets.duckdns-key.path}" "${settingsFileRuntimePath}"
      '';

      script = ''
        ${getExe pkgs.godns} -c ${settingsFileRuntimePath}
      '';

      serviceConfig = {
        DynamicUser = true;
        User = config.users.users.user.name;
        Group = config.users.users.user.group;
        RuntimeDirectory = "godns";
      };
    };
  };
}

