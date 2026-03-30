{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Include the necessary packages and configuration for Apple Silicon support.
      ./apple-silicon-support

      # Machines that have a desktop env
      /data/nixos/share/desktop.nix

      # Shared config of all machines
      /data/nixos/share/common.nix
    ];

  # AArch64 machine
  nixpkgs.hostPlatform = "aarch64-linux";

  # our hostname
  networking.hostName = "zeta";

  # hostid, important for ZFS pool
  networking.hostId = "cce4e4c1";

  # german laptop keyboard
  services.xserver.xkb.layout = "de";
}
