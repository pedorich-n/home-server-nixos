{
  flake,
  lib,
  ...
}:
{
  flake.ciJobs =
    let
      geekomA5 = flake.nixosConfigurations.geekomA5;
      minecraftConfig = geekomA5.config.services.minecraft-servers.servers."monkey-guys-1";
    in
    lib.mkMerge [
      {
        "${geekomA5.pkgs.stdenv.hostPlatform.system}" = {
          n8n = geekomA5.config.services.n8n.package;
          netdata = geekomA5.config.services.netdata.package;
          minecraftServer = minecraftConfig.package;
          minecraftModpack = minecraftConfig.package.passthru.modpack;
        };
      }
    ];
}
