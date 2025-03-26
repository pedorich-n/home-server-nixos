data "onepassword_vault" "homelab" {
  name = "HomeLab"
}

data "onepassword_item" "items" {
  for_each = toset(var.items)

  vault = data.onepassword_vault.homelab.uuid
  title = each.key
}

locals {
  secrets = {
    for key, item in data.onepassword_item.items : key => {
      for section in item.section : section.label => {
        for field in section.field : field.label => field.value
      }
    }
  }
}
