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
    device = "/dev/disk/by-id/nvme-Seagate_FireCuda_530_ZP4000GM30013_7VS01VBM-part1";
    fsType = "vfat";
    neededForBoot = true;
    options = [ "fmask=0022" "dmask=0022" ];
  };
}
