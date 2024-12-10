{ pkgs, lib, ... }: {
  # Removes X server from dependencies
  programs.vim.packageConfigurable = lib.mkOverride 950 (pkgs.vim-full.override {
    features = "normal";
    guiSupport = false;
  });
}
