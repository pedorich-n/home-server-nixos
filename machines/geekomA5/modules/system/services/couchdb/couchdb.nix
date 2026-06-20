{
  config,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.couchdb;

  # rootStorageDir = "/mnt/store/couchdb";
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

  services.couchdb = {
    enable = true;
    bindAddress = "127.0.0.1";
    port = portsCfg.port;

    # databaseDir = "${rootStorageDir}/data";
    # viewIndexDir = "${rootStorageDir}/index";

    extraConfigFiles = [
      config.sops.templates."couchdb/admin.ini".path
    ];

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
        origins = "app://obsidian.md,capacitor://localhost,http://localhost";
        methods = "GET, PUT, POST, HEAD, DELETE";
        headers = "accept, authorization, content-type, origin, referer";
      };

      couchdb = {
        max_document_size = 50000000;
      };
    };
  };
}
