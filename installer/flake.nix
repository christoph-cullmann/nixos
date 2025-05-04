{
  description = "installation media";
  inputs.nixos.url = "nixpkgs/nixos-unstable";
  outputs = { self, nixos }: {
    nixosConfigurations = {
      exampleIso = nixos.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal-new-kernel-no-zfs.nix"
          ({ config, lib, pkgs, ... }: {
            boot.supportedFilesystems = [ "bcachefs" ];
            boot.kernelPackages = lib.mkOverride 0 pkgs.linuxPackages_latest;
            networking.wireless.enable = false;
            networking.networkmanager.enable = true;
          })
        ];
      };
    };
  };
}
