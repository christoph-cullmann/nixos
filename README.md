# Christoph Cullmann's NixOS configuration

# build unstable minimal installer

```zsh
cd installer
nix --extra-experimental-features flakes --extra-experimental-features nix-command build .#nixosConfigurations.exampleIso.config.system.build.isoImage

caligula burn result/iso/nixos-*-x86_64-linux.iso
```
