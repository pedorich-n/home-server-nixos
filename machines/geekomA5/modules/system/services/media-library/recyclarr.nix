{
  config,
  systemdLib,
  pkgs-unstable,
  ...
}:
let
  portsCfg = config.custom.networking.ports.tcp;
in
{
  systemd.services.recyclarr = {
    unitConfig = systemdLib.requiresAfter [
      config.systemd.services.radarr.name
      config.systemd.services.sonarr.name
    ];
  };

  services.recyclarr = {
    enable = true;
    package = pkgs-unstable.recyclarr;

    schedule = "*-*-* 03:00:00"; # Every day at 3:00 AM

    # See https://recyclarr.dev/reference/configuration
    configuration = {
      radarr = {

        # From https://recyclarr.dev/wiki/guide-configs/ HD Bluray + WEB
        radarr-main = {
          base_url = "http://127.0.0.1:${portsCfg.radarr.portStr}";
          api_key._secret = config.sops.secrets."radarr/api/key".path;

          # Names from `recyclarr list naming radarr`
          media_naming = {
            folder = "jellyfin-tmdb";
            movie = {
              rename = true;
              standard = "jellyfin-tmdb";
            };
          };

          quality_definition = {
            type = "movie";
          };

          quality_profiles = [
            {
              trash_id = "d1d67249d3890e49bc12e275d989a7e9"; # HD Bluray + WEB
              reset_unmatched_scores = {
                enabled = true;
              };
            }
          ];

          custom_formats = [
            {
              trash_ids = [
                "dc98083864ea246d05a42df0d05f81cc" # x265 (HD)
              ];
              assign_scores_to = [
                {
                  name = "HD Bluray + WEB";
                  score = 0;
                }
              ];
            }
            {
              trash_ids = [
                "839bea857ed2c0a8e084f3cbdbd65ecb" # x265 (no HDR/DV)
              ];
              assign_scores_to = [
                {
                  name = "HD Bluray + WEB";
                }
              ];
            }
          ];
        };
      };

      sonarr = {
        # From https://recyclarr.dev/wiki/guide-configs/ WEB 1080p
        sonarr-main = {
          base_url = "http://127.0.0.1:${portsCfg.sonarr.portStr}";
          api_key._secret = config.sops.secrets."sonarr/api/key".path;

          # Names from `recyclarr list naming sonarr`
          media_naming = {
            series = "jellyfin-tvdb";
            season = "default";
            episodes = {
              rename = true;
              standard = "default";
              daily = "default";
              anime = "default";
            };
          };

          quality_definition = {
            type = "series";
          };

          quality_profiles = [
            {
              trash_id = "9d142234e45d6143785ac55f5a9e8dc9"; # WEB-1080p (Alternative)
              name = "WEB-1080p";
              reset_unmatched_scores = {
                enabled = true;
              };
            }
          ];

          custom_formats = [
            {
              trash_ids = [
                "3bc5f395426614e155e585a2f056cdf1" # Season Pack
              ];
              assign_scores_to = [
                {
                  name = "WEB-1080p";
                }
              ];
            }
            {
              trash_ids = [
                "47435ece6b99a0b477caf360e79ba0bb" # x265 (HD)
              ];
              assign_scores_to = [
                {
                  name = "WEB-1080p";
                  score = 0;
                }
              ];
            }
            {
              trash_ids = [
                "9b64dff695c2115facf1b6ea59c9bd07" # x265 (no HDR/DV)
              ];
              assign_scores_to = [
                {
                  name = "WEB-1080p";
                }
              ];
            }
          ];
        };
      };
    };
  };
}
