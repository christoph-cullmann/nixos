# build unstable installer

{
  description = "installation media";
  inputs.nixos.url = "nixpkgs/nixos-unstable";
  outputs = { self, nixos }: {
    nixosConfigurations = {
      exampleIso = nixos.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ];
      };
    };
  };
}

git init
git add flake.nix
nix --extra-experimental-features flakes --extra-experimental-features nix-command build .#nixosConfigurations.exampleIso.config.system.build.isoImage

sudo dd if=result/iso/nixos-24.05.20240108.317484b-x86_64-linux.iso of=/dev/sda bs=4M conv=fsync

# good ZFS links

- https://openzfs.github.io/openzfs-docs/Getting%20Started/NixOS/Root%20on%20ZFS.html
- https://carjorvaz.com/posts/installing-nixos-with-root-on-tmpfs-and-encrypted-zfs-on-a-netcup-vps/
- https://astrid.tech/2021/12/17/0/two-disk-encrypted-zfs/
- https://mzhang.io/posts/2022-05-09-installing-nixos-on-encrypted-zfs/
