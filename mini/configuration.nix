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

  # host name
  networking.hostName = "mini";

  # amd graphics
  hardware.opengl.extraPackages = with pkgs; [ amdvlk rocm-opencl-icd rocm-opencl-runtime ];
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ amdvlk ];
}
