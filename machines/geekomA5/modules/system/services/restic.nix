{ config, lib, pkgs-unstable, ... }:
let
  package = pkgs-unstable.restic;

  mkEveryDayAt = time: "*-*-* ${time}";
in
{
  options = {
    # See https://discourse.nixos.org/t/how-can-i-configure-default-values-lib-mkdefault-for-options-in-a-submodule-option/42100/3
    # See https://github.com/NixOS/nixpkgs/issues/24653#issuecomment-292684727
    services.restic.backups = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        config = {
          package = lib.mkDefault package;

          timerConfig = {
            Persistent = lib.mkDefault true;
          };

          extraBackupArgs = lib.mkDefault [
            "--tag auto"
          ];

          environmentFile = lib.mkDefault config.age.secrets."${name}_restic_environment".path;
          repositoryFile = lib.mkDefault config.age.secrets."${name}_restic_repository".path;
          passwordFile = lib.mkDefault config.age.secrets."${name}_restic_password".path;
        };
      }));
    };
  };

  config = {
    environment.systemPackages = [ package ];

    services.restic.backups = {
      immich.timerConfig.OnCalendar = mkEveryDayAt "02:00:00"; # Every day at 02:00
      grist.timerConfig.OnCalendar = mkEveryDayAt "02:30:00"; # Every day at 02:30
      maloja.timerConfig.OnCalendar = mkEveryDayAt "02:35:00"; # Every day at 02:35
      paperless.timerConfig.OnCalendar = mkEveryDayAt "02:40:00"; # Every day at 02:40
    };
  };
}
