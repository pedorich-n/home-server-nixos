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