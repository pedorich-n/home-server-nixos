locals {
  tailnet_key_expiration    = 90 * 86400 // 90 days in seconds
  tailnet_key_rotate_period = 75         // Days

  auth_keys = {
    initrd = tailscale_tailnet_key.initrd
  }
}

resource "time_rotating" "tailnet_key" {
  rotation_days = local.tailnet_key_rotate_period
}

resource "tailscale_tailnet_key" "initrd" {
  description         = "Initrd"
  reusable            = true
  ephemeral           = true
  preauthorized       = true
  expiry              = local.tailnet_key_expiration
  recreate_if_invalid = "always"
  tags = [
    "tag:initramfs",
    "tag:ssh"
  ]

  lifecycle {
    replace_triggered_by = [time_rotating.tailnet_key]
  }
}

resource "onepassword_item" "tailscale_keys" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Tailscale_Managed"
  category = "secure_note"

  section {
    label = "Auth_Keys"

    dynamic "field" {
      for_each = local.auth_keys

      content {
        label = field.key
        type  = "CONCEALED"
        value = field.value.key
      }
    }
  }
}
