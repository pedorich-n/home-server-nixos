{ inputs, ... }: {
  imports = [
    inputs.flake-parts.flakeModules.partitions
  ];

  partitions.dev = {
    extraInputsFlake = ../dev;
    module = {
      imports = [
        ../dev/flake-module.nix
      ];

      perSystem = { pkgs, ... }: {
        treefmt.config = {
          projectRoot = ../.;

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

              shellcheck = {
                options = [
                  "--exclude=SC2148" # Disable shebang check https://www.shellcheck.net/wiki/SC2148
                ];
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
    };
  };

  partitionedAttrs = {
    devShells = "dev";
    checks = "dev";
    formatter = "dev";
  };
}
