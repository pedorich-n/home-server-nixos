{
  inputs,
  config,
  pkgs-unstable,
  ...
}:

let
  portsCfg = config.custom.networking.ports.tcp.rustfs;
in
{
  disabledModules = [ "services/web-servers/rustfs.nix" ];
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/web-servers/rustfs.nix" ];

  custom.networking.ports.tcp.rustfs = {
    port = 45100;
    openFirewall = false;
  };

  services.rustfs = {
    enable = true;
    package = pkgs-unstable.rustfs;
    user = "rustfs";
    group = "rustfs";

    environmentFile = config.sops.secrets."rustfs/main.env".path;

    settings = {
      RUSTFS_VOLUMES = "/mnt/external/rustfs";
      RUSTFS_ADDRESS = ":${portsCfg.portStr}";
      RUSTFS_CONSOLE_ENABLE = "false";
    };
  };
}
