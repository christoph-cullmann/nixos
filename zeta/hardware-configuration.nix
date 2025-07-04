{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # basic drivers
  boot.initrd.availableKernelModules = [ "uas" ];

  # /boot efi partition to boot in UEFI mode
  fileSystems."/boot" = {
    device = "/dev/disk/by-id/nvme-APPLE_SSD_AP1024Z_0ba01e0141400628-part4";
    fsType = "vfat";
    neededForBoot = true;
    options = [ "fmask=0022" "dmask=0022" ];
  };
}
