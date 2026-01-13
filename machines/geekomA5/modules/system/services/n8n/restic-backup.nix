{
  config,
  lib,
  pkgs,
  ...
}:
let
  backupFolder = "/tmp/n8n-backup";
in
{
  #NOTE - See also global config at
  #LINK - machines/geekomA5/modules/system/services/restic/restic.nix
  services.restic.backups = {
    n8n = {
      paths = [
        backupFolder
      ];

      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];

      backupPrepareCommand = lib.getExe (
        pkgs.writeShellApplication {
          name = "n8n-backup-prepare";

          runtimeInputs = [
            config.services.n8n.package
          ];
          text = ''
            mkdir -p "${backupFolder}"
            export HOME="${config.services.n8n.environment.N8N_USER_FOLDER}"

            n8n export:entities --outputDir="${backupFolder}"
          '';
        }
      );

      backupCleanupCommand = ''
        rm -r "${backupFolder}"
      '';
    };
  };
}
