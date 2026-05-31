{
  inputs,
  autheliaLib,
  config,
  pkgs-unstable,
  lib,
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
  disabledModules = [ "services/web-apps/olivetin.nix" ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/olivetin.nix"
  ];

  warnings = lib.optional (lib.versionAtLeast config.system.nixos.release "26.05") "The updated Olivetin module now available in stable";

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
      ];
    };
  };

  services.olivetin = {
    enable = true;
    package = pkgs-unstable.olivetin-3k;

    path = [
      config.systemd.package
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
          popupOnStart = "execution-dialog-stdout-only";
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
          popupOnStart = "execution-dialog-stdout-only";
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
          popupOnStart = "execution-dialog-stdout-only";
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
      ];
    };
  };
}
