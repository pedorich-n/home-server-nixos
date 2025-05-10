resource "tailscale_acl" "acl" {
  acl = <<EOT
    {
      "tagOwners": {
        "${local.tags.server}": [], // Not used for any ACL yet
        "${local.tags.initrd}": [],
        "${local.tags.ssh}": []
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
            "100.113.5.10:80"
          ] 
        }
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
