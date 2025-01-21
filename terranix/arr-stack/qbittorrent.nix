{ domain, lib, ... }:
let
  inherit (lib) tfRef;

  baseUrl = "http://qbittorrent.${domain}/api/v2";
  baseDownloadPath = "/data/downloads/torrent";

  defaultHeaders = {
    "Content-Type" = "application/x-www-form-urlencoded";
  };

  defaultResponseCodes = [ "200" ];

  preferences = {
    bypass_auth_subnet_whitelist = "0.0.0.0/0";
    bypass_auth_subnet_whitelist_enabled = true;
    bypass_local_auth = true;

    save_path = "${baseDownloadPath}/complete";
    temp_path = "${baseDownloadPath}/incomplete";

    excluded_file_names = lib.concatStringsSep "\n" [ "*.lnk" ];

    dht = false;
    pex = false;
    lsd = false;
    anonymous_mode = false;

    max_ratio = 2;
    queueing_enabled = false;
  };
in
{
  locals = {
    # TODO: add "audiobooks" "movies"
    qbittorrent_categories = tfRef ''toset(["tv", "prowlarr"])'';
  };

  resource = {
    terracurl_request = {
      qbittorrent_preferences = {
        name = "setPreferences";
        method = "POST";
        url = "${baseUrl}/app/setPreferences";
        response_codes = defaultResponseCodes;
        headers = defaultHeaders;
        request_body = "json=${builtins.toJSON preferences}";

        lifecycle = {
          prevent_destroy = true;
        };
      };

      qbittorrent_categories = {
        for_each = tfRef "local.qbittorrent_categories";
        name = "createCategory_\${each.key}";
        method = "POST";
        url = "${baseUrl}/torrents/createCategory";
        response_codes = defaultResponseCodes;
        headers = defaultHeaders;
        request_body = "category=\${each.key}&savePath=\${each.key}";

        destroy_url = "${baseUrl}/torrents/removeCategories";
        destroy_method = "DELETE";
        destroy_headers = defaultHeaders;
        destroy_response_codes = defaultResponseCodes;
      };
    };
  };
}
