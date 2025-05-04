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

  # /nix volume with the system & all persistent data
  fileSystems."/nix" = {
    device = "/dev/disk/by-id/nvme-Seagate_FireCuda_530_ZP4000GM30013_7VS01VBM-part2:/dev/disk/by-id/nvme-CT2000P5PSSD8_213330E4ED05-part2:/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S69ENF0R846614L-part2";
    fsType = "bcachefs";
    neededForBoot = true;
  };
}
