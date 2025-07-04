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
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.memtest86.enable = true;

  # our hostname
  networking.hostName = "miku";
  networking.hostId = "4d00f481";

  # EurKey layout
  services.xserver.xkb.layout = "eu";
}
