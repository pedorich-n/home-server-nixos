{
  inputs,
  config,
  lib,
  systemdLib,
  networkingLib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.papra;
in
{
  disabledModules = [ "services/web-apps/papra.nix" ];
  imports = [ "${inputs.nixpkgs-papra}/nixos/modules/services/web-apps/papra.nix" ];

  custom = {
    networking.ports.tcp.papra = {
      port = 33000;
      openFirewall = false;
    };

    services.caddy.hosts.papra = {
      upstream = "http://127.0.0.1:${portsCfg.portStr}";
    };
  };

  systemd.services.papra = {
    unitConfig = lib.mkMerge [
      (systemdLib.requisiteAfter [
        "zfs.target"
      ])
    ];
  };

  services.papra = {
    enable = true;

    environment = {
      SERVER_HOSTNAME = "127.0.0.1";
      PORT = portsCfg.port;
      APP_BASE_URL = networkingLib.mkLocalUrl "papra";

      DATABASE_URL = "file:/mnt/store/papra/data/db.sqlite";

      DOCUMENT_STORAGE_DRIVER = "filesystem";
      DOCUMENT_STORAGE_FILESYSTEM_ROOT = "/mnt/external/papra-library";

      CONTENT_EXTRACTION_STRATEGY = "internal";
      DOCUMENTS_OCR_LANGUAGES = "eng,ukr,jpn";

      AUTH_IS_REGISTRATION_ENABLED = "false";
      AUTH_IS_PASSWORD_RESET_ENABLED = "false";
      AUTH_IS_EMAIL_VERIFICATION_REQUIRED = "false";
      AUTH_FIRST_USER_AS_ADMIN = "true";
      AUTH_IP_ADDRESS_HEADERS = "X-Forwarded-For";
      AUTH_PROVIDERS_EMAIL_IS_ENABLED = "false";

      INGESTION_FOLDER_IS_ENABLED = "false";

      AI_IS_ENABLED = "false";
    };

    environmentFiles = [
      config.sops.secrets."papra/main.env".path
      config.sops.templates."papra/oidc.env".path
    ];
  };
}
