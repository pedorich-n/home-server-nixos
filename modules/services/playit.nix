{ config, ... }: {
  services.playit = {
    enable = true;
    user = "playit";
    group = "playit";
    secretPath = config.age.secrets.playit-secret.path;
    runOverride = {
      "62884177-5592-45a9-9662-492b42407881" = [{ port = 43000; }]; # Also 43001
      "c0310a34-1ed3-4c6d-94f8-739c1d6b2f0f" = [{ port = 44080; }];
    };
  };
}
