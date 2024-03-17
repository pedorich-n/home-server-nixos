{ config, lib, pkgs, ... }:

let
  cfg = config.services.trilium-server;

  settingsFormat = pkgs.formats.ini { };
  finalSettingsFile = if (cfg.settingsFile != null) then cfg.settingsFile else settingsFormat.generate "config.ini" cfg.settings;
in
{
  disabledModules = [ "services/web-apps/trilium.nix" ];

  options.services.trilium-server = with lib; {
    enable = mkEnableOption (lib.mdDoc "trilium-server");

    package = lib.mkPackageOption pkgs "trilium-server" { };

    settings = mkOption {
      description = lib.mdDoc ''
        Configuration for `trilium-server`.

        See https://github.com/zadam/trilium/blob/master/config-sample.ini 
        for supported values.
      '';

      type = types.submodule {
        freeformType = settingsFormat.type;
      };

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

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/trilium";
      description = lib.mdDoc ''
        The directory storing the notes database and the configuration.
      '';
    };

    # TODO: expose user and group

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

      users.groups.trilium = { };
      users.users.trilium = {
        description = "Trilium User";
        group = "trilium";
        home = cfg.dataDir;
        isSystemUser = true;
      };

      systemd.services.trilium-server = {
        wantedBy = [ "multi-user.target" ];
        environment.TRILIUM_DATA_DIR = cfg.dataDir;
        serviceConfig = {
          ExecStart = lib.getExe' cfg.package "trilium-server";
          User = "trilium";
          Group = "trilium";
          PrivateTmp = "true";
        };
      };

      # TODO: use cfg.user cfg.group
      systemd.tmpfiles.rules = [
        "d  ${cfg.dataDir}            0750 trilium trilium - -"
        "L+ ${cfg.dataDir}/config.ini -    trilium trilium - ${finalSettingsFile}"
      ];

    }

    (lib.mkIf cfg.nginx.enable {
      services.nginx = {
        enable = true;
        virtualHosts."${cfg.nginx.hostName}" = {
          locations."/" = {
            proxyPass = "http://${cfg.host}:${toString cfg.port}/";
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
