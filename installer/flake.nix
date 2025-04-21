{
  description = "installation media";
  inputs.nixos.url = "nixpkgs/nixos-unstable";
  outputs = { self, nixos }: {
    nixosConfigurations = {
      exampleIso = nixos.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({ config, pkgs, ... }: {
            networking.wireless.enable = false;
            networking.networkmanager.enable = true;
          })
        ];
      };
    };
  };
}
