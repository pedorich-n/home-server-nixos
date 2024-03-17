{ config, lib, pkgs, ... }:

let
  name = "trilium";

  cfg = config.services.trilium-server;

  settingsFormat = pkgs.formats.ini { };
  settingsFile = settingsFormat.generate "config.ini" cfg.settings;

  settingsType = with lib; types.submodule {
    freeformType = settingsFormat.type;

    options = {
      Network = mkOption {
        type = types.submodule {
          # Copy of `iniSection` from `pkgs.formats.ini`
          # TODO: come up with a better way?
          freeformType = with lib.types; attrsOf (nullOr (oneOf [ bool int float str ]));

          options = {
            port = mkOption {
              type = types.port;
              description = mdDoc "Port to bind to";
              default = 8080;
            };
          };
        };
      };
    };
  };
in
{
  # TODO: upstream to nixpkgs?
  disabledModules = [ "services/web-apps/trilium.nix" ];

  options.services.trilium-server = with lib; {
    enable = mkEnableOption (lib.mdDoc "trilium-server");

    package = mkPackageOption pkgs "trilium-server" { };

    settings = mkOption {
      description = lib.mdDoc ''
        Configuration for `trilium-server`.

        See https://github.com/zadam/trilium/blob/master/config-sample.ini 
        for supported values.
      '';

      type = settingsType;

      default = {
        General = {
          instanceName = "Trilium";
          noAuthentication = false;
          noBackup = false;
          noDesktopIcon = true;
        };

        Network = {
          host = "127.0.0.1";
          port = 8080;
          https = false;
          trustedReverseProxy = false;
        };
      };

      example = literalExpression ''
        General = {
          instanceName = "Trilium";
          noAuthentication = false;
          noBackup = false;
          noDesktopIcon = true;
        };

        Network = {
          host = "127.0.0.1";
          port = 8080;
          https = false;
          trustedReverseProxy = "loopback";
        };
      '';
    };

    settingsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression "/path/to/config.ini";
      description = lib.mdDoc ''
        Path to Trilium's configuration file to use.

        {option}`settingsFile` takes precedence over {option}`settings`
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Opens the specified TCP port for Trilium
      '';
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/${name}";
      description = lib.mdDoc ''
        The directory storing the notes database and the configuration.
      '';
    };

    user = mkOption {
      type = types.str;
      default = name;
      description = lib.mdDoc "User account under which trilium runs.";
    };

    group = mkOption {
      type = types.str;
      default = name;
      description = lib.mdDoc "Group account under which trilium runs.";
    };

    nginx = mkOption {
      default = { };
      description = lib.mdDoc ''
        Configuration for nginx reverse proxy.
      '';

      type = types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = lib.mdDoc ''
              Configure the nginx reverse proxy settings.
            '';
          };

          hostName = mkOption {
            type = types.str;
            description = lib.mdDoc ''
              The hostname use to setup the virtualhost configuration
            '';
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      meta.maintainers = with lib.maintainers; [ fliegendewurst ];

      networking.firewall = lib.mkIf cfg.openFirewall {
        allowedTCPPorts = [ cfg.port ];
      };

      users = {
        users = lib.optionalAttrs (cfg.user == name) {
          ${name} = {
            description = "Trilium User";
            group = cfg.group;
            home = cfg.dataDir;
            isSystemUser = true;
          };
        };

        groups = lib.optionalAttrs (cfg.group == name) {
          ${name} = { };
        };
      };

      systemd.services.trilium-server = {
        wantedBy = [ "multi-user.target" ];
        environment.TRILIUM_DATA_DIR = cfg.dataDir;
        serviceConfig = {
          ExecStart = "${lib.getExe cfg.package}";
          User = cfg.user;
          Group = cfg.group;
          PrivateTmp = "true";
        };
      };

      systemd.tmpfiles.rules = [
        "d  ${cfg.dataDir}            0750 ${cfg.user} ${cfg.group} - -"
        "L+ ${cfg.dataDir}/config.ini -    ${cfg.user} ${cfg.group} - ${settingsFile}"
      ];
    }

    (lib.mkIf cfg.nginx.enable {
      services.nginx = {
        enable = true;
        virtualHosts."${cfg.nginx.hostName}" = {
          locations."/" = {
            proxyPass = "http://${cfg.host}:${toString cfg.settings.port}/";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection 'upgrade';
              proxy_set_header Host $host;
              proxy_cache_bypass $http_upgrade;
            '';
          };
          extraConfig = ''
            client_max_body_size 0;
          '';
        };
      };
    })
  ]);
}
