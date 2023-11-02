{ lib, pkgs, ... }: {
  # https://docs.papermc.io/paper/aikars-flags
  # TODO: look into https://github.com/etil2jz/etil-minecraft-flags?
  aikarFlagsWith = memory: builtins.concatStringsSep " " [
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
  ];

  mkPluginSymlinks = with lib.attrsets; attrs: mapAttrs' (name: value: nameValuePair "plugins/${name}.jar" value) attrs;

  mkConsoleAccessSymlink = name: {
    # TODO: use ${lib.getExe' pkgs.sudo "sudo"} once in stable
    "console-access.sh" = pkgs.writeShellScript "minecraft-console-${name}" ''
      ${pkgs.sudo}/bin/sudo -u minecraft ${lib.getExe pkgs.tmux} -S /run/minecraft/${name}.sock attach
    '';
  };
}
