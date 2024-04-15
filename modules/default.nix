{ self }: {
  core = self.lib.list-modules { src = ./core; };
  custom = self.lib.list-modules { src = ./custom; };
}
