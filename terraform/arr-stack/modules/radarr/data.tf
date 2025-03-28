data "terracurl_request" "naming" {
  name           = "radarr-naming"
  url            = "https://raw.githubusercontent.com/TRaSH-Guides/Guides/refs/heads/master/docs/json/radarr/naming/radarr-naming.json"
  method         = "GET"
  response_codes = [200]
}

data "terracurl_request" "quality_definitions" {
  name           = "radarr-quality-definitions"
  url            = "https://raw.githubusercontent.com/TRaSH-Guides/Guides/refs/heads/master/docs/json/radarr/quality-size/movie.json"
  method         = "GET"
  response_codes = [200]
}

data "radarr_quality_definitions" "existing" {

}