{ lib, ... }: {
  _module.args.systemdLib = {
    requiresAfter = services: cfg: cfg // {
      Requires = (cfg.Requires or [ ]) ++ (if (lib.isList services) then services else [ services ]);
      After = (cfg.After or [ ]) ++ (if (lib.isList services) then services else [ services ]);
    };
  };
}
