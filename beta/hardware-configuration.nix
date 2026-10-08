{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # basic drivers
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "uas" "sd_mod" ];

  # Intel CPU
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = true;

  # Intel graphics
  boot.initrd.kernelModules = [ "i915" ];

  # /boot efi partition to boot in UEFI mode
  fileSystems."/boot" = {
    device = "/dev/disk/by-id/ata-APPLE_SSD_SM0256F_S1K4NYCFA46727-part1";
    fsType = "vfat";
    neededForBoot = true;
    options = [ "fmask=0077" "dmask=0077" ];
  };
}
