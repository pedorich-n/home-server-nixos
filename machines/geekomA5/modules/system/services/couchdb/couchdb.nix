{
  config,
  pkgs,
  lib,
  networkingLib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.couchdb;

  bootstrap = pkgs.callPackage ./_bootstrap.nix {
    baseUrl = networkingLib.mkUrl "couchdb";
    dbNameFile = config.sops.secrets."couchdb/db/obsidian_livesync/name".path;
    adminUsernameFile = config.sops.secrets."couchdb/users/admin/username".path;
    adminPasswordFile = config.sops.secrets."couchdb/users/admin/password".path;
    userUsernameFile = config.sops.secrets."couchdb/users/obsidian_livesync/username".path;
    userPasswordFile = config.sops.secrets."couchdb/users/obsidian_livesync/password".path;
    bindAddress = config.services.couchdb.bindAddress;
    bindPort = portsCfg.portStr;
  };

  rootStorageFolder = "/mnt/store/couchdb";
in
{
  custom = {
    networking.ports.tcp.couchdb = {
      port = 32500;
      openFirewall = false;
    };

    services.caddy.hosts.couchdb = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
    };
  };

  systemd.services.couchdb = {
    serviceConfig = {
      ExecStartPost = "-${lib.getExe bootstrap}";
    };
  };

  services.couchdb = {
    enable = true;
    bindAddress = "127.0.0.1";
    port = portsCfg.port;

    extraConfigFiles = [
      config.sops.templates."couchdb/admin.ini".path
    ];

    databaseDir = rootStorageFolder;
    viewIndexDir = rootStorageFolder;
    configFile = "${rootStorageFolder}/local.ini";

    extraConfig = {
      # Basic settings from https://github.com/vrtmrz/obsidian-livesync/blob/c57b8a5f4e0a4826b84/utils/couchdb/couchdb-init.sh
      chttpd = {
        require_valid_user = true;
        enable_cors = true;
        max_http_request_size = 4294967296;
      };

      chttpd_auth = {
        require_valid_user = true;
      };

      httpd = {
        WWW-Authenticate = ''Basic realm="couchdb"'';
        enable_cors = true;
      };

      cors = {
        credentials = true;
        origins = "app://obsidian.md,capacitor://localhost,http://localhost,${networkingLib.mkUrl "couchdb"}";
        methods = "GET, PUT, POST, HEAD, DELETE";
        headers = "accept, authorization, content-type, origin, referer";
      };

      couchdb = {
        max_document_size = 50000000;
      };
    };
  };
}
