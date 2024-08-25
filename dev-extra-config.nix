_: {
  perSystem = { pkgs, ... }: {
    treefmt.config.settings.formatter = {
      djlint = {
        command = pkgs.djlint;
        options = [
          "--profile=jinja"
          "--extension=j2"
          "--indent=2"
          "--preserve-leading-space"
          "--preserve-blank-lines"
          "--reformat"
          "--warn"
          "--quiet"
        ];
        includes = [ "*.j2" ];
      };
    };
  };
}
