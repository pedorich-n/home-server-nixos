{
  config,
  pkgs,
  networkingLib,
  lib,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;

  artistRenames = {
    # Spotify name -> MusicBrainz name
    "Aquarium" = "Аквариум";
    "DakhaBrakha" = "ДахаБраха";
    "Kino" = "Кино";
    "Krovostok" = "Кровосток";
    "Lyapis Trubetskoy" = "Ляпис Трубецкой";
    "Mumiy Troll" = "Мумий Тролль";
    "Naadia" = "Наадя";
    "Naik Borzov" = "Найк Борзов";
    "Okean Elzy" = "Океан Ельзи";
    "Samoe Bolshoe Prostoe Chislo" = "Самое Большое Простое Число";
    "Splean" = "Сплин";
    "Vagonovozhatye" = "Вагоновожатые";
    "Vyacheslav Butusov" = "Вячеслав Бутусов";
    "Zemfira" = "Земфира";
    "[Би-2]" = "Би-2";
    "И Друг Мой Грузовик..." = "...и Друг Мой Грузовик";
    "Морэ & Рэльсы" = "МОРЭ&РЭЛЬСЫ";
  };

  mkRenameRule = source: target: {
    search = source;
    replace = target;
  };
in
{
  sops.templates = {
    "music-history/multiscrobbler/config.json" = {
      owner = config.users.users.user.name;
      group = config.users.users.user.group;
      restartUnits = [
        "multiscrobbler.service"
      ];

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
                # First, replace known artist name variants with the correct ones,
                # then try to match with MusicBrainz,
                # and if that fails use the native algorithm of Multi-Scrobbler (extract fields from source and apply some heuristics)
                preCompare = [
                  {
                    type = "user";
                    name = "ArtistRenames";
                    artists = lib.mapAttrsToList mkRenameRule artistRenames;
                  }
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
                  requestTimeout = 10000;
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
