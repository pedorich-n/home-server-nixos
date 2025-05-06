locals {
  indexers_torrent = {
    therarbg = {
      name           = "TheRARBG"
      app_profile_id = prowlarr_sync_profile.automatic.id
      priority       = 10
      fields = [
        { name = "baseUrl", text_value = "https://therarbg.to/" },
        { name = "definitionFile", text_value = "therarbg" },
        { name = "sort", number_value = 0 } # Created desc
      ]
    }

    milkie = {
      name     = "Milkie"
      priority = 20
      fields = [
        { name = "baseUrl", text_value = "https://milkie.cc/" },
        { name = "definitionFile", text_value = "milkie" },
        { name = "apikey", text_value = var.indexer_credentials.Milkie.api_key }
      ]
    }

    torrentleech = {
      name     = "TorrentLeech"
      priority = 25
      fields = [
        { name = "baseUrl", text_value = "https://www.torrentleech.org/" },
        { name = "definitionFile", text_value = "torrentleech" },
        { name = "exclude_archives", bool_value = false },
        { name = "exclude_scene", bool_value = false },
        { name = "freeleech", bool_value = false },
        { name = "sort", number_value = 0 }, # Sort by Created
        { name = "type", number_value = 1 }, # Sort desc
        { name = "username", text_value = var.indexer_credentials.TorrentLeech.username },
        { name = "password", text_value = var.indexer_credentials.TorrentLeech.password }
      ]
    }


    toloka = {
      name            = "Toloka"
      priority        = 30
      implementation  = "Toloka"
      config_contract = "TolokaSettings"
      fields = [
        { name = "baseUrl", text_value = "https://toloka.to/" },
        { name = "stripCyrillicLetters", bool_value = false },
        { name = "freeleechOnly", bool_value = false },
        { name = "username", text_value = var.indexer_credentials.Toloka.username },
        { name = "password", sensitive_value = var.indexer_credentials.Toloka.password }
      ]
    }

    rutracker = {
      name            = "Rutracker"
      priority        = 30
      implementation  = "RuTracker"
      config_contract = "RuTrackerSettings"
      fields = [
        { name = "baseUrl", text_value = "https://rutracker.org/" },
        { name = "russianLetters", bool_value = false },
        { name = "useMagnetLinks", bool_value = false },
        { name = "addRussianToTitle", bool_value = false },
        { name = "moveFirstTagsToEndOfReleaseTitle", bool_value = false },
        { name = "moveAllTagsToEndOfReleaseTitle", bool_value = false },
        { name = "username", text_value = var.indexer_credentials.RuTracker.username },
        { name = "password", sensitive_value = var.indexer_credentials.RuTracker.password }
      ]
    }
  }
}


resource "prowlarr_indexer" "torrent" {
  for_each = local.indexers_torrent

  name            = each.value.name
  enable          = true
  app_profile_id  = lookup(each.value, "app_profile_id", data.prowlarr_sync_profile.standard.id)
  implementation  = lookup(each.value, "implementation", "Cardigann")
  config_contract = lookup(each.value, "config_contract", "CardigannSettings")
  protocol        = "torrent"
  priority        = each.value.priority
  fields = concat([
    { name = "baseSettings.limitsUnit", number_value = 0 }, # 0 means Day, 1 means Hour
    { name = "torrentBaseSettings.preferMagnetUrl", bool_value = false }
  ], each.value.fields)
}
