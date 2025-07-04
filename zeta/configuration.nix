{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Include the necessary packages and configuration for Apple Silicon support.
      ./apple-silicon-support
      # Shared config of all machines
      /data/nixos/share/common.nix
    ];

  # AArch64 machine
  nixpkgs.hostPlatform = "aarch64-linux";

  # our hostname
  networking.hostName = "zeta";
  networking.hostId = "cce4e4c1";

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
