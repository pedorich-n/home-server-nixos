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
          level = "info";
        };
        cache = {
          valkey = "redis://host.containers.internal:${portsCfg.redis-multiscrobbler.portStr}";
        };

        sources = [
          {
            name = "spotify";
            enable = true;
            type = "spotify";
            id = "spotify";
            data = {
              clientId = config.sops.placeholder."music-history/multiscrobbler/spotify/client_id";
              clientSecret = config.sops.placeholder."music-history/multiscrobbler/spotify/client_secret";
            };
            options = {
              scrobbleBacklog = true;
              playTransform = {
                preCompare = [
                  {
                    # if MusicBrainz is successful then do NOT run native,
                    # only run native if MusicBrainz fails to find a match (onFailure)
                    type = "musicbrainz";
                    name = "MusicBrainz";
                    onSuccess = "stop";
                    onFailure = "continue";
                  }
                  {
                    type = "native";
                  }
                ];
              };
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
            id = "maloja";
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
            id = "koito";
            configureAs = "client";
            data = {
              token = config.sops.placeholder."music-history/multiscrobbler/koito/api_key";
              username = config.sops.placeholder."music-history/multiscrobbler/koito/username";
              url = networkingLib.mkUrl "koito";
            };
          }
        ];

        transformers = [
          {
            # From https://docs.multi-scrobbler.app/configuration/transforms/musicbrainz/#sensible-default-1
            name = "MusicBrainz";
            type = "musicbrainz";
            data = {
              apis = [
                {
                  contact = config.custom.secrets.plaintext.variables.email;
                }
              ];
            };
            defaults = {
              releaseStatusPriority = [
                "official"
              ];
              releaseGroupPrimaryTypePriority = [
                "album"
                "single"
                "ep"
              ];
              releaseCountryPriority = [
                "XW" # Worldwide
              ];
              searchArtistMethod = "native";
              searchOrder = [
                "isrc" # International Standard Recording Code
                "basic" # Combination of artist, album, track names
                "artist" # Attempt to extract artist names from the track
              ];
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
