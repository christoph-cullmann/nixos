# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Shared config of all machines
      /data/nixos/common.nix
    ];

  # intel graphics
  hardware.opengl.extraPackages = with pkgs; [ intel-media-driver intel-compute-runtime ];

  # our hostname
  networking.hostName = "neko";

  # use NetworkManager
  networking.useDHCP = false;
  networking.networkmanager.enable = true;
}
