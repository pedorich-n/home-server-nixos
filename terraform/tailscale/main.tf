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

resource "tailscale_device_key" "server" {
  device_id           = data.tailscale_device.server.id
  key_expiry_disabled = true
}

resource "tailscale_acl" "acl" {
  acl = <<EOT
    {
      "tagOwners": {
        "tag:initramfs": [],
        "tag:ssh": []
      },
      "acls": [
        {
          // Allow all members to connect to any node
          "action": "accept", 
          "src": [ 
            "autogroup:member"
          ], 
          "dst": [
            "*:*"
          ] 
        }, 
      ],
      "ssh": [
        {
          "action": "accept", 
          "src": [ 
            "autogroup:owner",
            "autogroup:admin"
          ], 
          "dst": [ 
            "tag:ssh" 
          ], 
          "users": [ 
            "autogroup:nonroot", 
            "root" 
          ]
        }
      ],
      "tests": [
        {
          // initramfs can't make outbound connections
          "src": "tag:initramfs", 
          "deny": [
            "100.113.5.10:22", 
            "192.168.10.5:22"
          ] 
        },
        {
          // But a user should be able to access any node
          "src": "pedorich.n@gmail.com", 
          "allow": [
            "tag:initramfs:2222", 
            "100.113.5.10:80"
          ] 
        }
      ],
      "sshTests": [
        {
          "src": "pedorich.n@gmail.com",
          "dst": [ 
            "tag:ssh" 
          ],
          "accept": [ 
            "root", 
            "user" 
          ]
        }
      ]
    }
  EOT
}