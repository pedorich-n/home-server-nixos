{
  config,
  lib,
  pkgs,
  ...
}:
let
  backupFolder = "/tmp/forgejo-backup";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups.forgejo = {
    paths = [
      backupFolder
    ];

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
    ];

    backupPrepareCommand = lib.getExe (
      pkgs.writeShellApplication {
        name = "forgejo-backup-prepare";

        runtimeInputs = [
          config.services.forgejo.package
          pkgs.sudo
        ];
        text = ''
          mkdir -p "${backupFolder}"
          chown "${config.services.forgejo.user}" "${backupFolder}"

          sudo -u "${config.services.forgejo.user}" forgejo dump \
            --work-path "${config.services.forgejo.stateDir}" \
            --type "zip" \
            --file "${backupFolder}/forgejo-dump.zip" \
            --verbose
        '';
      }
    );

    backupCleanupCommand = ''
      rm -r "${backupFolder}"
    '';
  };
}
