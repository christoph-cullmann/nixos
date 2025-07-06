{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Include the necessary packages and configuration for Apple Silicon support.
      ./apple-silicon-support

      # Shared config of all laptops
      /data/nixos/share/laptop.nix

      # Shared config of all machines
      /data/nixos/share/common.nix
    ];

  # AArch64 machine
  nixpkgs.hostPlatform = "aarch64-linux";

  # our hostname
  networking.hostName = "zeta";
  networking.hostId = "cce4e4c1";
}
