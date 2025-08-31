{
  config,
  lib,
  pkgs-unstable,
  ...
}:
let
  package = pkgs-unstable.restic;

  mkEveryDayAt = time: "*-*-* ${time}";
in
{
  options = {
    # See https://discourse.nixos.org/t/how-can-i-configure-default-values-lib-mkdefault-for-options-in-a-submodule-option/42100/3
    # See https://github.com/NixOS/nixpkgs/issues/24653#issuecomment-292684727
    services.restic.backups = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            config = {
              package = lib.mkDefault package;

              timerConfig = {
                Persistent = lib.mkDefault true;
              };

              extraBackupArgs = lib.mkDefault [
                "--tag auto"
              ];

              environmentFile = lib.mkDefault config.sops.secrets."restic/${name}/environment.env".path;
              repositoryFile = lib.mkDefault config.sops.secrets."restic/${name}/repository".path;
              passwordFile = lib.mkDefault config.sops.secrets."restic/${name}/password".path;
            };
          }
        )
      );
    };
  };

  config = {
    environment.systemPackages = [ package ];

    services.restic.backups = {
      # Potentially takes a long time
      immich.timerConfig.OnCalendar = mkEveryDayAt "02:00:00";

      # Takes a couple of minutes due to service stop and start
      jellyfin.timerConfig.OnCalendar = mkEveryDayAt "02:15:00";

      # Short ones
      audiobookshelf.timerConfig.OnCalendar = mkEveryDayAt "02:30:00";
      grist.timerConfig.OnCalendar = mkEveryDayAt "02:31:00";
      maloja.timerConfig.OnCalendar = mkEveryDayAt "02:32:00";
      paperless.timerConfig.OnCalendar = mkEveryDayAt "02:33:00";
      homeassistant.timerConfig.OnCalendar = mkEveryDayAt "02:34:00";
    };
  };
}
