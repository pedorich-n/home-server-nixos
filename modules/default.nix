{ flake }: {
  core = flake.lib.list-modules { src = ./core; };
  custom = flake.lib.list-modules { src = ./custom; };
}
