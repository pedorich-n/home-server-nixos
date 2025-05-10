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
