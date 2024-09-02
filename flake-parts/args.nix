{ self, ... }: {
  # Helps to avoid confusion between haumea's and flake-parts' `self`. This `self` is flake-parts' and points to the flake (outputs).
  _module.args.flake = self;
}
