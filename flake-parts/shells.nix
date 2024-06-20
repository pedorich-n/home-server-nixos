_: {
  perSystem = { pkgs, ... }: {
    devShells = {
      version-updater = pkgs.mkShellNoCC {
        name = "version-updater";

        packages = [
          pkgs.nvchecker
        ];
      };
    };
  };
}
