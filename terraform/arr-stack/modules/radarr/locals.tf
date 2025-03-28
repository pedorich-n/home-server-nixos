locals {
  naming_trash = jsondecode(data.terracurl_request.naming.response)

  quality_definitions_trash = jsondecode(data.terracurl_request.quality_definitions.response).qualities

  quality_definitions_existing = { for item in data.radarr_quality_definitions.existing.quality_definitions : item.title => item }

  radarr_quality_definitions_trash_mapped = {
    for quality in local.quality_definitions_trash : quality.quality => {
      title          = quality.quality
      min_size       = quality.min
      max_size       = quality.max
      preferred_size = quality.preferred
      id             = local.quality_definitions_existing[quality.quality].id
    } if contains(keys(local.quality_definitions_existing), quality.quality)
  }
}
