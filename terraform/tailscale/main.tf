module "onepassword" {
  source = "../modules/onepassword"
  items  = ["Tailscale"]
}

resource "tailscale_dns_nameservers" "global_dns" {
  nameservers = [
    "1.1.1.1",
    "9.9.9.9"
  ]
}

resource "tailscale_dns_split_nameservers" "server" {
  domain      = var.server_domain
  nameservers = data.tailscale_device.server.addresses
}

resource "local_file" "server_addresses" {
  content = jsonencode({
    addresses = [for addr in data.tailscale_device.server.addresses : addr if provider::assert::ipv4(addr)]
  })

  filename = "${path.module}/../../managed-files/server_addresses.json"
}
