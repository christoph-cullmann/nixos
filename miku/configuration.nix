{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Shared config of all machines
      /data/nixos/share/common.nix
    ];

  # our hostname
  networking.hostName = "miku";
  networking.hostId = "4d00f481";

  # EurKey layout
  services.xserver.xkb.layout = "eu";
}
