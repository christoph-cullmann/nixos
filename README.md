# Christoph Cullmann's NixOS configuration

# build unstable minimal installer

```zsh
cd installer
nix --extra-experimental-features flakes --extra-experimental-features nix-command build .#nixosConfigurations.exampleIso.config.system.build.isoImage

doas dd if=result/iso/nixos-*-x86_64-linux.iso of=/dev/sda bs=4M conv=fsync
```

# reset home manager

```zsh
rm /data/home/cullmann/.local/state/nix/profiles/home-manager* /date/home/cullmann/.local/state/home-manager/gcroots/current-home
rm /data/home/sandbox-kde/.local/state/nix/profiles/home-manager* /date/home/sandbox-kde/.local/state/home-manager/gcroots/current-home
```
