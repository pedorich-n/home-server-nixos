{ config, ... }: {
  services.playit = {
    enable = true;
    user = "playit";
    group = "playit";
    secretPath = config.age.secrets.playit-secret.path;
    runOverride = {
      "62884177-5592-45a9-9662-492b42407881" = [{ port = 43000; }];
      "5ee160f1-2374-454a-8c00-81bf4747855f" = [{ port = 19132; }];
    };
  };
}
