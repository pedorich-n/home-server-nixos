{
  config,
  pkgs,
  lib,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
in
{
  sops.templates = lib.mkIf (config.services ? ngrok && config.services.ngrok.enable) {
    "ngrok.yaml" = {
      owner = config.services.ngrok.user;
      inherit (config.services.ngrok) group;

      file = yamlFormat.generate "ngrok-template.yaml" {
        authtoken = config.sops.placeholder."ngrok/token";
        console_ui = "iftty";
        version = 2;
        tunnels = {
          "telegram-airtable-lessons" = {
            proto = "http";
            addr = config.custom.networking.ports.tcp.lessons-calendar-loader.port;
            schemes = [
              "https"
            ];
            domain = config.sops.placeholder."ngrok/tunnels/telegram-airtable-lessons/domain";
            oauth = {
              provider = "google";
              allow_emails = [
                config.sops.placeholder."ngrok/tunnels/telegram-airtable-lessons/allow_emails/1"
                config.sops.placeholder."ngrok/tunnels/telegram-airtable-lessons/allow_emails/2"
              ];
            };
          };
        };
      };
    };
  };

}
