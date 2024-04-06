{ self }: {
  core = self.lib.filesystem.list-modules { src = ./core; };
  custom = self.lib.filesystem.list-modules { src = ./custom; };
}
