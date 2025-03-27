_: {
  perSystem = { pkgs, ... }: {
    treefmt.config = {
      settings = {
        global.excludes = [
          "**/_sources/*"
          "**/.terraform.lock.hcl"
        ];
        formatter = {
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
      programs = {
        shellcheck = {
          enable = true;
          excludes = [ "**/.envrc" ];
        };

        terraform = {
          enable = true;
        };
      };
    };
  };
}
