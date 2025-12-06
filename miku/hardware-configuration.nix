{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # basic drivers
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];

  # AMD CPU
  boot.kernelModules = [ "kvm-amd" ];
  hardware.cpu.amd.updateMicrocode = true;

  # AMD graphics
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.ollama.package = pkgs.ollama-rocm;

  # /boot efi partition to boot in UEFI mode
  fileSystems."/boot" = {
    device = "/dev/disk/by-id/nvme-KINGSTON_SFYRD4000G_50026B7686EC5F33-part1";
    fsType = "vfat";
    neededForBoot = true;
    options = [ "fmask=0077" "dmask=0077" ];
  };
}
