{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Shared config of all workstations
      /data/nixos/share/workstation.nix

      # Machines that have a desktop env
      /data/nixos/share/desktop.nix

      # Shared config of all machines
      /data/nixos/share/common.nix
    ];

  # x86-64 machine
  nixpkgs.hostPlatform = "x86_64-linux";

  # our hostname
  networking.hostName = "neko";

  # hostid, important for ZFS pool
  networking.hostId = "4836f248";

  # ethernet card to use
  systemd.network.networks."10-wan".matchConfig.Name = "enp11s0";
}
