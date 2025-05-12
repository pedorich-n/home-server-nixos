# Initrd Recovery

If a headless machine gets stuck during boot, there's normally no way to access it without connecting a display and keyboard.  
However, there's a solution: running an SSH server in the initrd allows remote access early in the boot process.  
See the [ArchWiki](https://wiki.archlinux.org/title/Arch_boot_process) for more info about the boot process.

Machines extending the `headless` preset have `sshd` (on port `2222`) enabled in initrd by default.  
For this to work properly, SSH host keys must be supplied. See the [`boot.initrd.network.ssh.hostKeys`](https://search.nixos.org/options?query=boot.initrd.network.ssh.hostKeys) config option.  
**Do not reuse the system’s regular SSH host keys!** It's best to generate separate keys specifically for initrd.

For remote access, Tailscale can also be enabled in initrd. See `custom.boot.initrd.network.tailscale.*` config options.  
When enabled, Tailscale creates an ephemeral node on the tailnet with the name `<hostname>-initrd`.

Note: Tailscale requires an auth key, which expires after a maximum of 90 days (unless OAuth client is used).  
This means the key must be rotated regularly, and a new initrd must be built each time.
