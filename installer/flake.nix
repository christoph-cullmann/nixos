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
            networking.networkmanager.enable = true;
            networking.wireless.enable = pkgs.lib.mkForce false;
            networking.wireless.iwd = {
              enable = true;
              settings.General.EnableNetworkConfiguration = true;
            };
          })
        ];
      };
    };
  };
}
