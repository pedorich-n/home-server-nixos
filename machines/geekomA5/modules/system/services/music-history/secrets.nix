{
  config,
  pkgs,
  networkingLib,
  ...
}:
{
  sops.templates = {
    "music-history/multiscrobbler/maloja.json" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;
      file = pkgs.writers.writeJSON "multiscrobbler-maloja.json" [
        {
          name = "maloja";
          enable = true;
          configureAs = "client";
          data = {
            url = "http://maloja:42010";
            apiKey = config.sops.placeholder."music-history/multiscrobbler/maloja/api_key";
          };
          options = {
            verbose = {
              match = {
                onNoMatch = true;
                confidenceBreakdown = true;
              };
            };
          };
        }
      ];
    };

    "music-history/multiscrobbler/spotify.json" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;
      file = pkgs.writers.writeJSON "multiscrobbler-spotify.json" [
        {
          name = "spotify";
          enable = true;
          data = {
            clientId = config.sops.placeholder."music-history/multiscrobbler/spotify/client_id";
            clientSecret = config.sops.placeholder."music-history/multiscrobbler/spotify/client_secret";
          };
          options = {
            scrobbleBacklog = true;
          };
        }
      ];
    };

    "music-history/multiscrobbler/koito.json" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;
      file = pkgs.writers.writeJSON "multiscrobbler-koito.json" [
        {
          name = "koito";
          enable = true;
          configureAs = "client";
          data = {
            token = config.sops.placeholder."music-history/multiscrobbler/koito/api_key";
            username = config.sops.placeholder."music-history/multiscrobbler/koito/username";
            url = networkingLib.mkUrl "koito";
          };
          options = {
            verbose = {
              match = {
                onNoMatch = true;
                confidenceBreakdown = true;
              };
            };
          };
        }
      ];
    };

    "music-history/maloja/api_keys.yaml" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;
      file = pkgs.writers.writeYAML "maloja-api-keys.yaml" {
        multiscrobbler = config.sops.placeholder."music-history/maloja/api_keys/multiscrobbler";
      };
    };
  };

}
