{
  config,
  lib,
  networkingLib,
  pkgs,
  ...
}:
let
  socketPath = "/run/forgejo/forgejo.sock";
in
{
  custom = {
    services.caddy.hosts.forgejo = {
      domain = networkingLib.mkDomain "git";
      upstream = "unix/${socketPath}";
    };
  };

  # Needed to access the socket file
  systemd.services.caddy.serviceConfig.SupplementaryGroups = [
    config.services.forgejo.group
  ];

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
          PROTOCOL = "http+unix";
          HTTP_ADDR = socketPath;
          UNIX_SOCKET_PERMISSION = "660";
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
        # Those have to be declared using string keys, because the INI converter doesn't support such level of nested attributes.
        "cron.update_checker".ENABLED = false;
        "cron.git_gc_repositories".ENABLED = true;
        "cron.delete_old_system_notices".ENABLED = true;
      };
    };

  };
}
