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

  titleRegexes = lib.map (regex: "/${regex}/i") [
    ''\s[–—−‐-]\s(?:[0-9]+\s)?Remaster(ed)?'' # Match " - Remastered", " - 2015 Remaster", etc.
    ''\((?:[0-9]+\s)?Remaster(ed)?\)'' # Match "(Remastered)", "(2015 Remaster)", etc.
    ''\s?(?:\([0-9]+['""`'′″]+\s+Version\))'' # Match "7' Version", " (7" Version)", etc.
    ''\s?[–—−‐-]\s[0-9]+['""`'′″]+\s+Version'' # Match " - 7' Version", etc.
    ''\s[–—−‐-]\sBonus(?:\s+Track)?'' # Match " - Bonus Track", "- Bonus", etc.
    ''\s?\(Bonus(?:\sTrack)?\)'' # Match " (Bonus Track)", " (Bonus)", etc.
    ''\s[–—−‐-]\sLive'' # Match " - Live", "- Live", etc.
    ''\s?\(Live\)'' # Match " (Live)", etc.
  ];
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
          level = "debug";
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
                /*
                  First, replace known artist name variants with the correct ones,
                  then clean up the title with some regexes (e.g. remove "Remastered", "7' Version", etc.),
                  then try to match with MusicBrainz,
                  and if that fails use the native algorithm of Multi-Scrobbler (extract fields from source and apply some heuristics)
                */
                preCompare = [
                  {
                    type = "user";
                    name = "ArtistRenames";
                    artists = lib.mapAttrsToList mkRenameRule artistRenames;
                  }
                  {
                    type = "user";
                    name = "CustomCleanup";
                    title = titleRegexes;
                  }
                  {
                    # if MusicBrainz is successful then do NOT run native, only run native if MusicBrainz fails to find a match
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
              /*
                This enables text similarity scroring between the source and MusicBrainz result. Default values are 0.3 for each field.
                By prioritizing the albumWeight and de-prioritizing the titleWeight MS will be more likely to match the correct release
                even if the title is "wrong", because I assume the album name coming from the source is correct, while title might contain extras like "Remasterd", "Live", etc.

                2.4 was chosen because `releaseCountryPriority` can produce max value of `2` (if the release is XW),
                so if there's an album with the same name that wasn't released worldwide,
                I want it to be ranked higher than an album with a different name that was released worldwide.
              */
              albumWeight = 2.4;
              artistWeight = 0.3;
              titleWeight = 0.3;

              releaseStatusPriority = [
                "official"
                "pseudo-release" # Transliterations, alternative titles, etc.
              ];
              # releaseGroupPrimaryTypePriority = [
              #   "ep"
              #   "single"
              #   "album"
              # ];
              # releaseGroupSecondaryTypePriority = [
              #   "compilation"
              # ];
              releaseCountryPriority = [
                "XW" # Worldwide
                "XE" # Europe
              ];
              searchArtistMethod = "native";

              # Here the earlier fields have higher priority.
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
