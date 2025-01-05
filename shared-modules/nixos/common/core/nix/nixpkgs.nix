{ lib, ... }: {
  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config = {
      allowUnfree = lib.mkDefault true;
    };
  };
}
