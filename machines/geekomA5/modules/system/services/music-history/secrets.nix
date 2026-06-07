{
  config,
  pkgs,
  networkingLib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;
in
{
  sops.templates = {
    "music-history/multiscrobbler/config.json" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;

      # See structure at https://docs.multi-scrobbler.app/playground/
      file = pkgs.writers.writeJSON "multiscrobbler-config.json" {
        base_url = networkingLib.mkUrl "multiscrobbler";
        logging = {
          level = "verbose";
        };
        cache = {
          valkey = "redis://host.containers.internal:${portsCfg.redis-multiscrobbler.portStr}";
        };

        sources = [
          {
            name = "spotify";
            enable = true;
            type = "spotify";
            data = {
              clientId = config.sops.placeholder."music-history/multiscrobbler/spotify/client_id";
              clientSecret = config.sops.placeholder."music-history/multiscrobbler/spotify/client_secret";
            };
            options = {
              scrobbleBacklog = true;
            };
          }
        ];

        clientDefaults = {
          verbose = {
            match = {
              onNoMatch = true;
              confidenceBreakdown = true;
            };
          };
        };

        clients = [
          {
            name = "maloja";
            enable = true;
            type = "maloja";
            configureAs = "client";
            data = {
              url = "http://maloja:42010";
              apiKey = config.sops.placeholder."music-history/multiscrobbler/maloja/api_key";
            };
          }

          {
            name = "koito";
            enable = true;
            type = "koito";
            configureAs = "client";
            data = {
              token = config.sops.placeholder."music-history/multiscrobbler/koito/api_key";
              username = config.sops.placeholder."music-history/multiscrobbler/koito/username";
              url = networkingLib.mkUrl "koito";
            };
          }
        ];
      };
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
