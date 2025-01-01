{ lib, ... }: {
  nixpkgs = {
    config = {
      allowUnfree = lib.mkDefault true;
    };
  };
}
