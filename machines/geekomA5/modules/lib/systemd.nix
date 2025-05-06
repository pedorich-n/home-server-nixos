_: {
  _module.args.systemdLib = {
    requiresAfter = services: {
      Requires = services;
      After = services;
    };

    bindsToAfter = services: {
      BindsTo = services;
      After = services;
    };
  };
}
