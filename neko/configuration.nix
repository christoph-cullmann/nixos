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
  networking.hostName = "neko";

  # main network interface via systemd-networkd
  networking.useDHCP = false;
  systemd.network.enable = true;
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "enp9s0";
    networkConfig.DHCP = "yes";
    linkConfig.RequiredForOnline = "routable";
  };

  # intel graphics
  hardware.opengl.extraPackages = with pkgs; [ intel-media-driver intel-compute-runtime ];
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ intel-media-driver ];
}
