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
      /data/nixos/share/common.nix
    ];

  # our hostname and an ID for ZFS
  networking.hostName = "beta";
  networking.hostId = "3f20def9";

  # german laptop keyboard
  services.xserver.xkb.layout = "de";
}
