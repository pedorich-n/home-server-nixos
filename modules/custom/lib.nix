{ inputs, self, ... } @args: {
  _module.args.customLib = inputs.haumea.lib.load {
    src = "${self}/lib/local";
    inputs = builtins.removeAttrs args [ "self" ];
  };
}
