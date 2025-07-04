{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Shared config of all machines
      /data/nixos/share/common.nix
    ];

  # x86-64 machine
  nixpkgs.hostPlatform = "x86_64-linux";

  # our hostname
  networking.hostName = "beta";
  networking.hostId = "c07bab49";

  # use NetworkManager, if we have WiFi, allows Plasma to manage connections
  # use iwd, only thing that works properly on e.g. Macs
  networking.networkmanager.enable = true;
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  # german laptop keyboard
  services.xserver.xkb.layout = "de";
}
