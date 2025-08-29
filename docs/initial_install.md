# Initial Install

## Using disko & nixos-anywhere

1. Generate custom bootable ISO: `nix run .#build-iso-minimal` or `just build-iso`
2. Burn the ISO onto USB using [Rufus](https://rufus.ie/en/)(dd mode)
3. Generate & use new SSH host & initrd host keys
   1. Run `just generate-host-keys`
   2. The output should contain path to the keys in the temporary folder
   3. Convert the newly generated public key(s) to age by running `just convert-host-keys <path-to-keys>`
   4. Add the converted `age` key(s) to `.sops.yaml` file in `home-server-nixos-secrets` repo
   5. Encrypt secrets & push the changes
   6. Fetch new secrets in this repo `nix flake update home-server-nixos-secrets`
   7. Copy the path to the keys from the `generate-host-keys`' output
4. Boot from the USB
> [!CAUTION]
> This will erase the disk and create new partitions. DATA WILL BE LOST
4. Run `nix run github:nix-community/nixos-anywhere -- --extra-files "<path-to-keys>" --flake ".#<machine>" root@nixos`
5. System should reboot into a newly installed profile
6. From now on `deploy-rs` can be used to deploy from another machine
7. Remove the generated secrets from this machine's temporary directory

### Notes:

- Minimal ISO doesn't have wireless connectivity enabled (yet?)

## Using regular flake (without disko)

> [!WARNING]  
> This is probably outdated

1. Download NixOS install ISO with GUI installer from https://nixos.org/download/
2. Burn the ISO onto USB using [Rufus](https://rufus.ie/en/)
3. Boot from the USB
4. Install NixOS using the GUI installer
5. Finish installation & reboot into installed NixOS
6. Edit `/etc/nixos/configuration.nix`, add
   ```nix
    services.openssh = {
        enable = true;
        settings = {
            PasswordAuthentication = true;
            PermitRootLogin = "yes";
        };
    };
   ```
7. Run `sudo nixos-rebuild switch`
8. Get the machine's key: `cat /etc/ssh/ssh_host_ed25519_key.pub`
9. Add new machine's key to `recipients.txt` file in `home-server-nixos-secrets` repo
10. Encrypt secrets
11. Fetch new secrets in this repo `nix flake lock --update-input home-server-nixos-secrets`
12. Deploy the actual NixOS configuration using `deploy-rs`: `nix run .#deploy-<machine>` or `just deploy-<machine>`
13. Reboot
14. Machine should run now custom NixOS configuration
