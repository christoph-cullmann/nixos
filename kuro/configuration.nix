# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Shared config of all machines
      /home/cullmann/install/nixos/common.nix
    ];

  # host name & id
  networking.hostName = "kuro";
  networking.hostId = "862cf3b5";
}
