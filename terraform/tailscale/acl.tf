resource "tailscale_acl" "acl" {
  acl = <<EOT
    {
      "tagOwners": {
        "${local.tags.server}": [], // Not used for any ACL yet
        "${local.tags.initrd}": [],
        "${local.tags.ssh}": [],
        "${local.tags.router}": [],
        "${local.tags.subnet}": []
      },
      "grants": [
        {
          // Allow all members to connect to any node
          "src": [ "autogroup:member" ], 
          "dst": [ "*" ],
          "ip": [ "*" ]
        }, 
        {
          // Allow routers to connect to any node
          "src": [ "${local.tags.router}" ], 
          "dst": [ "*" ],
          "ip": [ "*" ]
        }
      ],
      "autoApprovers": {
        "exitNode": [ "${local.tags.router}" ],
        "routes": {
          "192.168.0.0/16": [ "${local.tags.subnet}" ]
        }
      },
      "ssh": [
        {
          "action": "accept", 
          "src": [ 
            "autogroup:owner",
            "autogroup:admin"
          ], 
          "dst": [ 
            "${local.tags.ssh}" 
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
          "src": "${local.tags.initrd}", 
          "deny": [
            "100.113.5.10:22", 
            "192.168.10.5:22"
          ] 
        },
        {
          // But a user should be able to access any node
          "src": "pedorich.n@gmail.com", 
          "allow": [
            "${local.tags.initrd}:2222",
            "${local.tags.initrd}:2222",
            "${local.tags.ssh}:22",
            "${local.tags.server}:443",
            "${local.tags.router}:443",
            "100.113.5.10:80"
          ] 
        },
        {
          // A router also should be able to access any node
          "src": "${local.tags.router}", 
          "allow": [
            "${local.tags.initrd}:2222",
            "${local.tags.ssh}:22",
            "${local.tags.router}:443",
            "${local.tags.server}:443",
            "100.113.5.10:80"
          ]
        },
      ],
      "sshTests": [
        {
          "src": "pedorich.n@gmail.com",
          "dst": [ 
            "${local.tags.ssh}" 
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
