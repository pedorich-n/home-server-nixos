{ pkgs, lib, ... }: {
  home.enableNixpkgsReleaseCheck = lib.mkDefault false; # Don't compare nixpkgs and HM versions
  nix.registry = lib.mkOverride 950 { }; # Use system level registries but allow overrides in users. (mkDefault already used in sharedModules)
  programs.keychain.enable = lib.mkOverride 950 false; # There's no need, but allow overrides in users
  programs.vim.packageConfigurable = lib.mkOverride 950 (pkgs.vim-full.override {
    features = "normal";
    guiSupport = false;
  });
}
