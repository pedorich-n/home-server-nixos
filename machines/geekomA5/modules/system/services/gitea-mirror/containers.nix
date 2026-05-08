{
  config,
  containerLib,
  networkingLib,
  ...
}:
let
  storeRoot = "/mnt/store/gitea-mirror";
  portsCfg = config.custom.networking.ports.tcp.gitea-mirror;
in
{
  custom = {
    networking.ports.tcp.gitea-mirror = {
      port = 32000;
      openFirewall = false;
    };

    services.caddy.hosts.gitea-mirror = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
    };
  };

  virtualisation.quadlet.containers.gitea-mirror = {
    wantsCaddy = true;
    wantsAuthelia = true;
    useGlobalContainers = true;
    usernsAuto = {
      enable = true;
      size = 65535;
    };

    containerConfig = {
      environments = {
        BETTER_AUTH_URL = networkingLib.mkUrl "gitea-mirror";

        PRIVATE_REPOSITORIES = "true";
        PUBLIC_REPOSITORIES = "true";
        INCLUDE_ARCHIVED = "true";
        SKIP_FORKS = "true";
        MIRROR_STARRED = "false";
        MIRROR_WIKI = "true";
        MIRROR_ISSUES = "false";
        MIRROR_METADATA = "false";
        MIRROR_ORGANIZATIONS = "false";

        GITEA_URL = networkingLib.mkUrl "git";
      };
      environmentFiles = [ config.sops.secrets."gitea-mirror/main.env".path ];
      volumes = [
        (containerLib.mkMappedVolumeForUser "${storeRoot}/data" "/app/data")
      ];
      publishPorts = [ "127.0.0.1:${portsCfg.portStr}:4321" ];
      inherit (containerLib.containerIds) user;
    };
  };

}
