locals {
  indexers_nzb = {
    nzbgeek = {
      name           = "NZBGeek"
      app_profile_id = prowlarr_sync_profile.standard.id
      priority       = 15
      fields = [
        { name = "baseUrl", text_value = "https://api.nzbgeek.info" },
        { name = "vipExpiration", text_value = "2030-12-13" },
        { name = "baseSettings.limitsUnit", number_value = 0 } # 0 means Day, 1 means Hour
      ]
    }

    nzbfinder = {
      name           = "NZBFinder"
      app_profile_id = prowlarr_sync_profile.standard.id
      priority       = 15
      fields = [
        { name = "baseUrl", text_value = "https://nzbfinder.ws" },
        { name = "vipExpiration", text_value = "2027-08-16" },
        { name = "baseSettings.queryLimit", number_value = 5000 },
        { name = "baseSettings.grabLimit", number_value = 5000 },
        { name = "baseSettings.limitsUnit", number_value = 0 } # 0 means Day, 1 means Hour
      ]
    }
  }

}

resource "prowlarr_indexer" "nzb" {
  for_each = local.indexers_nzb

  name            = each.value.name
  enable          = true
  redirect        = true
  implementation  = "Newznab"
  config_contract = "NewznabSettings"
  protocol        = "usenet"
  app_profile_id  = each.value.app_profile_id
  priority        = each.value.priority
  fields = concat([
    { name = "apiPath", text_value = "/api" },
    { name = "apiKey", sensitive_value = var.indexer_credentials[each.value.name].api_key }
  ], each.value.fields)
}
