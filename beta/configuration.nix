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
  networking.hostName = "beta";

  # german laptop keyboard
  services.xserver.xkb.layout = "de";
}
