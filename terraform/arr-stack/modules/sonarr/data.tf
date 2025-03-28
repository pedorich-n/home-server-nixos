data "terracurl_request" "naming" {
  name           = "sonarr-naming"
  url            = "https://raw.githubusercontent.com/TRaSH-Guides/Guides/refs/heads/master/docs/json/sonarr/naming/sonarr-naming.json"
  method         = "GET"
  response_codes = [200]
}

data "terracurl_request" "quality_definitions" {
  name           = "sonarr-quality-definitions"
  url            = "https://raw.githubusercontent.com/TRaSH-Guides/Guides/refs/heads/master/docs/json/sonarr/quality-size/series.json"
  method         = "GET"
  response_codes = [200]
}

data "sonarr_quality_definitions" "existing" {

}