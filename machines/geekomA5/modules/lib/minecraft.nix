{ lib, ... }: {
  _module.args.minecraftLib = {
    # https://docs.papermc.io/paper/aikars-flags
    aikarFlagsWith = { memory }: builtins.concatStringsSep " " [
      "-Xms${memory}"
      "-Xmx${memory}"
      "-XX:+UseG1GC"
      "-XX:+ParallelRefProcEnabled"
      "-XX:MaxGCPauseMillis=200"
      "-XX:+UnlockExperimentalVMOptions"
      "-XX:+DisableExplicitGC"
      "-XX:+AlwaysPreTouch"
      "-XX:G1NewSizePercent=30"
      "-XX:G1MaxNewSizePercent=40"
      "-XX:G1HeapRegionSize=8M"
      "-XX:G1ReservePercent=20"
      "-XX:G1HeapWastePercent=5"
      "-XX:G1MixedGCCountTarget=4"
      "-XX:InitiatingHeapOccupancyPercent=15"
      "-XX:G1MixedGCLiveThresholdPercent=90"
      "-XX:G1RSetUpdatingPauseTimePercent=5"
      "-XX:SurvivorRatio=32"
      "-XX:+PerfDisableSharedMem"
      "-XX:MaxTenuringThreshold=1"
      "-Dlog4j.skipJansi=false" # Needed for https://modrinth.com/mod/jline4mcdsrv
    ];

    mkPluginSymlinks = with lib.attrsets; attrs: mapAttrs' (name: value: nameValuePair "plugins/${name}.jar" value) attrs;

    mkPackwizSymlinks = { pkg, folder ? "" }:
      let
        predicate = path: path != null && (lib.hasPrefix folder path);

        manifest = lib.importJSON "${pkg}/packwiz.json";
        cachedLocations = builtins.filter predicate (builtins.map (entry: entry.cachedLocation or null) (builtins.attrValues manifest.cachedFiles));
        files = lib.genAttrs cachedLocations (relPath: "${pkg}/${relPath}");
      in
      files;

    # mkConsoleAccessSymlink = name: {
    #   "console-access.sh" = pkgs.writeShellScript "minecraft-console-${name}" ''
    #     ${lib.getExe pkgs.sudo} -u minecraft ${lib.getExe pkgs.tmux} -S /run/minecraft/${name}.sock attach
    #   '';
    # };
  };
}
