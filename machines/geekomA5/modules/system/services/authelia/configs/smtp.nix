{
  config,
  pkgs,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
in
{

  sops.templates."authelia/smtp.yaml" = {
    owner = config.services.authelia.instances.main.user;
    group = config.services.authelia.instances.main.group;
    restartUnits = [
      config.systemd.services.authelia-main.name
    ];

    file = yamlFormat.generate "authelia-smtp-template.yaml" {
      notifier.smtp = {
        address = "submissions://smtp.purelymail.com:465";
        username = config.sops.placeholder."authelia/smtp/username";
        password = config.sops.placeholder."authelia/smtp/password";
        sender = "Authelia HomeLab <${config.sops.placeholder."authelia/smtp/username"}>";
        subject = "{title}";
      };
    };
  };
}
