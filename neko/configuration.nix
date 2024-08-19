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
      /nix/data/nixos/share/common.nix
    ];

  # our hostname and an ID for ZFS
  networking.hostName = "neko";
  networking.hostId = "cf5a5ee6";

  # EurKey layout
  services.xserver.xkb.layout = "eu";
}
