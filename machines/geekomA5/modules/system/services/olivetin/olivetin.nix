{
  autheliaLib,
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp.olivetin;

  systemdUnitArg = {
    name = "unit";
    description = "Systemd unit to view logs for";
    type = "ascii_identifier";
  };
in
{
  custom = {
    networking.ports.tcp.olivetin = {
      port = 32400;
      openFirewall = false;
    };

    services.caddy.hosts.olivetin = {
      upstream = "http://localhost:${portsCfg.portStr}";
    };
  };

  systemd.services.olivetin = {
    serviceConfig = {
      SupplementaryGroups = [
        config.users.groups.systemd-journal.name
        config.users.groups.tomb.name
      ];

      EnvironmentFile = config.sops.secrets."olivetin/main.env".path;
    };
  };

  services.olivetin = {
    enable = true;
    package = pkgs-unstable.olivetin-3k;

    path = [
      config.systemd.package
      "/run/wrappers"
    ];

    extraConfigFiles = [
      config.sops.templates."olivetin/oidc.yaml".path
    ];

    settings = {
      ListenAddressSingleHTTPFrontend = "127.0.0.1:${portsCfg.portStr}";

      accessControlLists = [
        {
          name = "admins";
          matchUsergroups = [
            autheliaLib.groups.Admins
          ];
          policy = {
            showDiagnostics = true;
            showLogList = true;
          };
          permissions = {
            view = true;
            exec = true;
            logs = true;
          };
          addToEveryAction = true;
        }
      ];

      defaultPolicy = {
        showDiagnostics = false;
        showLogList = false;
      };

      defaultPermissions = {
        view = false;
        exec = false;
        logs = false;
      };

      authLocalUsers = {
        enabled = true;
        users = [
          {
            username = "automation";
            usergroup = "admins";
            apiKey = "{{ .Env.AUTOMATION_API_KEY }}";
          }
        ];
      };

      actions = [
        {
          title = "Journalctl";
          icon = ''<iconify-icon icon="bi:book"></iconify-icon>'';
          popupOnStart = "execution-dialog-stdout-only";
          exec = [
            "journalctl"
            "--no-hostname"
            "--no-pager"
            "--output"
            "short-iso"
            "--lines"
            "{{ lines }}"
            "--unit"
            "{{ unit }}"
          ];
          arguments = [
            systemdUnitArg
            {
              name = "lines";
              description = "Number of log lines to show";
              type = "int";
              default = 100;
            }
          ];
        }
        {
          title = "Systemctl status";
          icon = ''<iconify-icon icon="bi:info-circle"></iconify-icon>'';
          popupOnStart = "execution-dialog-stdout-only";
          exec = [
            "systemctl"
            "status"
            "--no-pager"
            "{{ unit }}"
          ];
          arguments = [
            systemdUnitArg
          ];
        }
        {
          title = "Systemctl start";
          icon = ''<iconify-icon icon="bi:play-circle"></iconify-icon>'';
          exec = [
            "systemctl"
            "--no-block"
            "start"
            "{{ unit }}"
          ];
          arguments = [
            systemdUnitArg
          ];
        }
        {
          title = "Systemctl stop";
          icon = ''<iconify-icon icon="bi:stop-circle"></iconify-icon>'';
          exec = [
            "systemctl"
            "--no-block"
            "stop"
            "{{ unit }}"
          ];
          arguments = [
            systemdUnitArg
          ];
        }
        {
          title = "Systemctl restart";
          icon = ''<iconify-icon icon="bi:arrow-repeat"></iconify-icon>'';
          exec = [
            "systemctl"
            "--no-block"
            "restart"
            "{{ unit }}"
          ];
          arguments = [
            systemdUnitArg
          ];
        }
        {
          title = "Tomb open";
          icon = ''<iconify-icon icon="bi:unlock"></iconify-icon>'';
          exec = [
            "sudo"
            (lib.getExe pkgs.custom-tomb.open)
            "/mnt/external/data-library/tomb/main.tomb"
            config.sops.secrets."tomb/main.key".path
            "/mnt/tomb"
          ];
          timeout = 10;
          popupOnStart = "execution-dialog";
          arguments = [
            {
              name = "tomb_key_pass";
              description = "Tomb key passphrase";
              type = "password";
            }
          ];
        }
        {
          title = "Tomb close";
          icon = ''<iconify-icon icon="bi:lock"></iconify-icon>'';
          exec = [
            "sudo"
            (lib.getExe pkgs.custom-tomb.close)
            "/mnt/tomb"
          ];
          timeout = 10;
          popupOnStart = "execution-dialog";
          arguments = [
            {
              description = "Are you sure?";
              type = "confirmation";
            }
          ];
        }
      ];

      dashboards = [
        {
          title = "Server management";
          type = "fieldset";
          contents = [
            {
              title = "Journalctl";
            }
            {
              title = "Systemctl status";
            }
            {
              title = "Systemctl start";
            }
            {
              title = "Systemctl stop";
            }
            {
              title = "Systemctl restart";
            }
          ];
        }
        {
          title = "Tomb management";
          type = "fieldset";
          contents = [
            {
              title = "Tomb open";
            }
            {
              title = "Tomb close";
            }
          ];
        }
      ];
    };
  };
}
