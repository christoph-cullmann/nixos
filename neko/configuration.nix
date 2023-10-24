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

  # use systemd-networkd, fixed IPv4, dynamic IPv6
  networking.hostName = "neko";
  networking.useDHCP = false;
  networking.nameservers = [ "192.168.13.1" ];
  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "enp10s0";
      address = [ "192.168.13.171/24" ];
      routes = [ { routeConfig.Gateway = "192.168.13.1"; } ];
      networkConfig.IPv6AcceptRA = true;
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
