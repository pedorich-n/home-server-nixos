{
  flake,
  lib,
  ...
}:
{
  flake.ciJobs =
    let
      geekomA5 = flake.nixosConfigurations.geekomA5;
    in
    lib.mkMerge [
      {
        "${geekomA5.pkgs.stdenv.hostPlatform.system}" = {
          # n8n = geekomA5.config.services.n8n.package;
          # netdata = geekomA5.config.services.netdata.package;
          hello = geekomA5.config.pkgs.hello;
        };
      }
    ];
}
