{ inputs, flake, ... } @args: {
  _module.args.customLib = inputs.haumea.lib.load {
    src = "${flake}/lib/local";
    inputs = args;
  };
}
