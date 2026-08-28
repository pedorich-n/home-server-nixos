{
  flake,
  lib,
  ...
}:
{
  flake.ciJobs =
    let
      geekomA5 = flake.nixosConfigurations.geekomA5;

      packageIfServiceEnabled =
        service:
        lib.mkIf geekomA5.config.services.${service}.enable {
          ${service} = geekomA5.config.services.${service}.package;
        };
    in
    {
      "${geekomA5.pkgs.stdenv.hostPlatform.system}" = lib.mkMerge [
        (packageIfServiceEnabled "netdata")
        (packageIfServiceEnabled "n8n")
      ];
    };
}
