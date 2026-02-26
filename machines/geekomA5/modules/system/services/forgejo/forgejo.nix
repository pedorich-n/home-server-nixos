{
  config,
  lib,
  networkingLib,
  pkgs,
  ...
}:
let
  portCfg = config.custom.networking.ports.tcp.forgejo;
in
{
  custom.networking.ports.tcp.forgejo = {
    port = 45100;
    openFirewall = false;
  };

  services = {
    forgejo = {
      enable = true;
      package = pkgs.forgejo;

      useWizard = false;

      repositoryRoot = "/mnt/store/forgejo/repositories";

      database = {
        type = "sqlite3";
      };

      secrets = {
        security = {
          SECRET_KEY = lib.mkForce config.sops.secrets."forgejo/secrets/secret_key".path;
          INTERNAL_TOKEN = lib.mkForce config.sops.secrets."forgejo/secrets/internal_token".path;
        };
      };

      settings = {
        server = {
          ROOT_URL = networkingLib.mkUrl "git";
          DOMAIN = networkingLib.mkDomain "git";
          PROTOCOL = "http";
          HTTP_PORT = portCfg.port;
          SSH_PORT = lib.head config.services.openssh.ports;
        };
        service = {
          DISABLE_REGISTRATION = true;
        };
        session = {
          COOKIE_SECURE = true;
        };
        oauth2 = {
          ENABLED = false;
        };
        oauth2_client = {
          ENABLE_OPENID_SIGNIN = true;
          ENABLE_AUTO_REGISTRATION = true;
          # Can be set to one of "nickname", "email" or "userid".
          USERNAME = "nickname";
        };
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.forgejo = {
        entryPoints = [ "web-secure" ];
        rule = "Host(`${networkingLib.mkDomain "git"}`)";
        service = "forgejo-secure";
      };

      services.forgejo-secure = {
        loadBalancer.servers = [ { url = "http://localhost:${portCfg.portStr}"; } ];
      };
    };
  };
}
