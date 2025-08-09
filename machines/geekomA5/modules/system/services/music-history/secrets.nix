{ config, pkgs, ... }:
let
  jsonFormat = pkgs.formats.json { };
  yamlFormat = pkgs.formats.yaml { };
in
{
  sops.templates = {
    "music-history/multiscrobbler/maloja.json" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;
      file = jsonFormat.generate "multiscrobbler-maloja.json" [
        {
          name = "maloja";
          enable = true;
          data = {
            url = "http://maloja:42010";
            apiKey = config.sops.placeholder."music-history/multiscrobbler/maloja/api_key";
            options = {
              verbose = {
                match = {
                  onNoMatch = true;
                  confidenceBreakdown = true;
                };
              };
            };
          };
        }
      ];
    };

    "music-history/multiscrobbler/spotify.json" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;
      file = jsonFormat.generate "multiscrobbler-spotify.json" [
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

    "music-history/maloja/api_keys.yaml" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;
      file = yamlFormat.generate "maloja-api-keys.yaml" {
        multiscrobbler = config.sops.placeholder."music-history/maloja/api_keys/multiscrobbler";
      };
    };
  };

}
