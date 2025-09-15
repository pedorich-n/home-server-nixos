locals {
  oauth_clients = {
    server = tailscale_oauth_client.server
    initrd = tailscale_oauth_client.initrd
  }
}

resource "tailscale_oauth_client" "server" {
  depends_on = [
    tailscale_acl.acl
  ]
  description = "Client to issue Auth Keys for servers"
  scopes      = ["auth_keys"]
  tags = [
    local.tags.server,
    local.tags.ssh
  ]
}

resource "tailscale_oauth_client" "initrd" {
  depends_on = [
    tailscale_acl.acl
  ]
  description = "Client to issue Auth Keys for Initrd"
  scopes      = ["auth_keys"]
  tags = [
    local.tags.initrd,
    local.tags.ssh
  ]
}

resource "onepassword_item" "tailscale_oauth_clients" {
  vault    = module.onepassword.vault_homelab.uuid
  title    = "Tailscale_OAuth_Clients"
  category = "secure_note"

  dynamic "section" {
    for_each = local.oauth_clients

    content {
      label = section.key

      field {
        label = "id"
        type  = "STRING"
        value = section.value.id
      }

      field {
        label = "secret"
        type  = "CONCEALED"
        value = section.value.key
      }
    }
  }
}
