{
  inputs = {
    nix-dev-flake = {
      url = "github:pedorich-n/nix-dev-flake/flake-partitions";
      flake = true;
    };
  };

  outputs = _: { };
}
