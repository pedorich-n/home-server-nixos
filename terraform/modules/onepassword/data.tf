data "onepassword_vault" "homelab" {
  name = "HomeLab"
}

data "onepassword_item" "items" {
  for_each = toset(var.items)

  vault = data.onepassword_vault.homelab.uuid
  title = each.key
}