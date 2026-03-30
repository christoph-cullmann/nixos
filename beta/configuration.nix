{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Shared config of all machines
      /data/nixos/share/common.nix

      # Machines that have a desktop env
      /data/nixos/share/desktop.nix
    ];

  # x86-64 machine
  nixpkgs.hostPlatform = "x86_64-linux";

  # our hostname
  networking.hostName = "beta";

  # hostid, important for ZFS pool
  networking.hostId = "c07bab49";

  # german laptop keyboard
  services.xserver.xkb.layout = "de";
}
