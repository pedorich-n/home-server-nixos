{ flake, inputs, ... }: {
  home-manager = {
    # Install HM into `/etc/profiles` rather than `$HOME/.nix-profile`. 
    # Not sure if this needed, but HM docs say that it might be enabled by default in the future, so I assume it's better to enable it.
    useUserPackages = true;
    # Reuse NixOS's pkgs. "Saves an extra Nixpkgs evaluation, adds consistency, and removes the dependency on NIX_PATH" - HM manual
    useGlobalPkgs = true;
    # File extension to add to backuped files
    backupFileExtension = ".bak";

    extraSpecialArgs = { inherit flake; };

    sharedModules = inputs.personal-home-manager.homeModules.sharedModules ++ [
      {
        home.enableNixpkgsReleaseCheck = false;
        nix.registry = { };
        programs.keychain.enable = false;
      }
    ];

    users = {
      root = {
        imports = [
          inputs.personal-home-manager.homeModules.common
        ];
      };

      user = {
        imports = [
          inputs.personal-home-manager.homeModules.common
        ];
      };
    };
  };
}
