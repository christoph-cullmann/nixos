# build unstable installer

{
  description = "installation media";
  inputs.nixos.url = "nixpkgs/nixos-unstable";
  outputs = { self, nixos }: {
    nixosConfigurations = {
      exampleIso = nixos.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
        ];
      };
    };
  };
}

git init
git add flake.nix
nix --extra-experimental-features flakes --extra-experimental-features nix-command build .#nixosConfigurations.exampleIso.config.system.build.isoImage

doas dd if=result/iso/nixos-*-x86_64-linux.iso of=/dev/sda bs=4M conv=fsync

# reset home manager

rm /data/home/cullmann/.local/state/nix/profiles/home-manager* /date/home/cullmann/.local/state/home-manager/gcroots/current-home
rm /data/home/sandbox-games/.local/state/nix/profiles/home-manager* /date/home/sandbox-games/.local/state/home-manager/gcroots/current-home
rm /data/home/sandbox-kde/.local/state/nix/profiles/home-manager* /date/home/sandbox-kde/.local/state/home-manager/gcroots/current-home
