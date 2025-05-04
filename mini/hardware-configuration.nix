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
  services.ollama.acceleration = "rocm";

  # /boot efi partition to boot in UEFI mode
  fileSystems."/boot" = {
    device = "/dev/disk/by-id/nvme-CT4000P3PSSD8_2325E6E63746-part1";
    fsType = "vfat";
    neededForBoot = true;
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # /nix volume with the system & all persistent data
  fileSystems."/nix" = {
    device = "/dev/disk/by-id/nvme-CT4000P3PSSD8_2325E6E63746-part2:/dev/disk/by-id/ata-CT2000MX500SSD1_2138E5D5061F-part2";
    fsType = "bcachefs";
    neededForBoot = true;
  };
}
