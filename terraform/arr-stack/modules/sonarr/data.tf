data "terracurl_request" "naming" {
  name           = "sonarr-naming"
  url            = "https://raw.githubusercontent.com/TRaSH-Guides/Guides/refs/heads/master/docs/json/sonarr/naming/sonarr-naming.json"
  method         = "GET"
  response_codes = [200]
}