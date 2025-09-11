_: {
  _module.args.systemdLib = {
    requiresAfter = services: {
      Requires = services;
      After = services;
    };

    requisiteAfter = services: {
      Requisite = services;
      After = services;
    };

    wantsAfter = services: {
      Wants = services;
      After = services;
    };

    bindsToAfter = services: {
      BindsTo = services;
      After = services;
    };
  };
}
