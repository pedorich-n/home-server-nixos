_: {
  perSystem = { pkgs, ... }: {
    apps = {
      generate-host-key.program = pkgs.callPackage ../pkgs/generate-host-key { };
    };
  };
}
