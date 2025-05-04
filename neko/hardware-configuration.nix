{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # basic drivers
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];

  # Intel CPU
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = true;

  # Intel graphics
  boot.initrd.kernelModules = [ "i915" ];

  # /boot efi partition to boot in UEFI mode
  fileSystems."/boot" = {
    device = "UUID=CFA5-46EA";
    fsType = "vfat";
    neededForBoot = true;
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # /nix volume with the system & all persistent data
  fileSystems."/nix" = {
    device = "UUID=686a90a2-93ac-40a6-a01d-c7b61cc47750";
    fsType = "bcachefs";
    neededForBoot = true;
  };
}
