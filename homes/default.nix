{ flake, inputs, ... }: {
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = ".bak";

    extraSpecialArgs = { inherit flake; inherit (inputs) nixpkgs; };

    sharedModules = inputs.personal-home-manager.homeModules.sharedModules;

    users = {
      user = {
        imports = [
          inputs.personal-home-manager.homeModules.common
          # ./user/home.nix
        ];

        home.enableNixpkgsReleaseCheck = false;
        programs.vim.enable = false;
      };
    };
  };
}
