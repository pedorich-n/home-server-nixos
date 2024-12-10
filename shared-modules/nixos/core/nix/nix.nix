{ inputs, lib, ... }:
let
  #TODO - more (all) inputs?
  inputsToUse = {
    inherit (inputs) nixpkgs nixpkgs-unstable;
  };
in
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "@wheel" ];
    };

    gc = {
      automatic = true;
      dates = lib.mkDefault "*-*-01,15 04:00"; # Two times a month at 04:00
      options = lib.mkDefault "--delete-older-than 30d";
    };


    # See https://gist.github.com/tpwrules/b0ab69330ff18da1f9842837ef290740
    # See https://github.com/ryan4yin/nixos-and-flakes-book/blob/d509b20039964d730848b66c46878be4555fe3d3/docs/best-practices/nix-path-and-flake-registry.md
    channel.enable = false; # remove nix-channel related tools & configs, use flakes instead.

    nixPath = builtins.map (name: "${name}=/etc/nix/inputs/${name}") (builtins.attrNames inputsToUse);

    registry = lib.mapAttrs' (name: input: { inherit name; value = { flake = input; }; }) inputsToUse;
  };

  environment.etc = lib.mapAttrs' (name: input: { name = "/nix/inputs/${name}"; value = { source = input.outPath; }; }) inputsToUse;
}
