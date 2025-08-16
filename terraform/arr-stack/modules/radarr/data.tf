data "terracurl_request" "naming" {
  name           = "radarr-naming"
  url            = "https://raw.githubusercontent.com/TRaSH-Guides/Guides/refs/heads/master/docs/json/radarr/naming/radarr-naming.json"
  method         = "GET"
  response_codes = [200]
}