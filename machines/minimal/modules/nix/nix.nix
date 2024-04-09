{ inputs, ... }:
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "@wheel" ];
    };

    nixPath = [
      "nixpkgs=${inputs.nixpkgs}"
    ];
  };
}
