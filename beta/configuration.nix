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

  # amd graphics
  hardware.graphics.extraPackages = with pkgs; [ amdvlk rocm-opencl-icd rocm-opencl-runtime ];

  # our hostname and an ID for ZFS
  networking.hostName = "mini";
  networking.hostId = "e925ccfb";

  # classic dhcpcd
  networking.networkmanager.enable = false;
}
