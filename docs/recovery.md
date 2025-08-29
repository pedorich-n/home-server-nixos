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

---

# Live CD Recovery

If the system goes past initrd step, but can't boot into normal mode it might get stuck in a process without a way to interact with it.
There are multiple ways to get out of this situation. One of them is to boot from a NixOS live CD/USB and either manually edit the config and rebuild the system or push a new build from a remote machine.

## nixos-enter

1. Generate custom bootable ISO: `nix run .#build-iso-minimal` or `just build-iso`
2. Burn the ISO onto USB using [Rufus](https://rufus.ie/en/)(dd mode)
3. Boot a live OS
4. Mount machine's partitions under `/mnt`:
   1. `mkdir -p /mnt/boot`
   2. Mount the root partition under `/mnt/`: `mount /dev/disk/by-partlabel/<ROOT> /mnt`
   3. Mount the `boot` partition under `/mnt/boot`: `mount /dev/disk/by-partlabel/<BOOT> /mnt/boot`
   4. Mount any other partitions under `/mnt` if present
5. At this point it should be possible to chroot into the system with `nixos-enter --root /mnt`.

## nixos-install

If the machine cannot be recovered from `nixos-enter` or it doesn't contain the editable config files a new build can be pushed from a remote machine.

1. Follow the steps from [nixos-enter](#nixos-enter) except the `nixos-enter` itself. Stay in the Live CD shell
2. On a remote machine build the new configuration with `nix build .#nixosConfigurations.<system>.config.system.build.toplevel --print-out-paths` or `just build-geekomA5` for geekomA5. The output will be the path of system derivation
3. Copy the new system derivation to a remote machine with `nix copy --to "ssh://root@<address>?remote-store='local?root=/mnt'" <store-path>`
   1. This will send the derivation and its dependencies to the machine at `<address>` to a store at `/mnt/nix/store`.
   2. See additional documentation in nix manual: [nix copy](https://nix.dev/manual/nix/2.28/command-ref/new-cli/nix3-copy), [ssh store](https://nix.dev/manual/nix/2.28/store/types/ssh-store), [local store](https://nix.dev/manual/nix/2.28/store/types/local-store)
4. On the Live CD shell run `nixos-install --no-root-passwd --no-channel-copy --system <store-path>`. This should install new system and make it first in the boot menu.

## Additional materials

- https://wiki.nixos.org/wiki/Change_root
- https://nixos.org/manual/nixos/stable/#sec-installation-manual-installing
- https://wiki.nixos.org/wiki/Bootloader
- Some of the steps were directly copied from [nixos-anywhere](https://github.com/nix-community/nixos-anywhere). Its code is a good source of information.
