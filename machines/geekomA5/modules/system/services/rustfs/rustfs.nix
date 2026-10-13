{
  inputs,
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

let
  portsCfg = config.custom.networking.ports.tcp.rustfs;

  gristPolicy = pkgs.writers.writeJSON "grist-policy.json" {
    Version = "2012-10-17";
    Statement = [
      {
        Effect = "Allow";
        Action = [ "s3:*" ];
        Resource = [
          "arn:aws:s3:::grist"
          "arn:aws:s3:::grist/*"
        ];
      }
    ];
  };

  bootstrap = pkgs.callPackage ./_bootstrap.nix {
    rustfs-cli = pkgs-unstable.rustfs-cli;
    adminAccessKeyFile = config.sops.secrets."rustfs/admin/access_key".path;
    adminSecretKeyFile = config.sops.secrets."rustfs/admin/secret_key".path;
    gristAccessKeyFile = config.sops.secrets."rustfs/grist/access_key".path;
    gristSecretKeyFile = config.sops.secrets."rustfs/grist/secret_key".path;
    bindAddress = "127.0.0.1";
    bindPort = portsCfg.portStr;
    inherit gristPolicy;
  };
in
{
  disabledModules = [ "services/web-servers/rustfs.nix" ];
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/web-servers/rustfs.nix" ];

  custom.networking.ports.tcp.rustfs = {
    port = 45100;
    openFirewall = false;
  };

  systemd.services.rustfs = {
    serviceConfig = {
      StateDirectory = "rustfs";
    };
  };

  services.rustfs = {
    enable = true;
    package = pkgs-unstable.rustfs;
    user = "rustfs";
    group = "rustfs";

    environmentFile = config.sops.secrets."rustfs/main.env".path;

    settings = {
      RUSTFS_VOLUMES = "/mnt/external/rustfs";
      RUSTFS_ADDRESS = "127.0.0.1:${portsCfg.portStr}";
      RUSTFS_CONSOLE_ENABLE = "false";
    };
  };

  custom.services.caddy.hosts.storage = {
    upstream = "http://127.0.0.1:${portsCfg.portStr}";
  };

  systemd.services.rustfs-bootstrap = {
    description = "Provision rustfs bucket, versioning, and grist service account";
    after = [ "rustfs.service" ];
    requires = [ "rustfs.service" ];
    before = [ "grist.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "rustfs";
      Group = "rustfs";
      WorkingDirectory = "/var/lib/rustfs";
      ExecStart = lib.getExe bootstrap;
    };
  };
}
