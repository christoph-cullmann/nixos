# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];

  # /boot efi partition to boot in UEFI mode
  fileSystems."/boot" =
    { device = "/dev/disk/by-id/nvme-CT4000P3PSSD8_2325E6E63746-part1";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
      neededForBoot = true;
    };

  # /nix encrypted btrfs for the remaining space
  boot.initrd.luks.devices."crypt0" = {
    device = "/dev/disk/by-id/nvme-CT4000P3PSSD8_2325E6E63746-part2";
    allowDiscards = true;
  };
  boot.initrd.luks.devices."crypt1" = {
    device = "/dev/disk/by-id/ata-CT2000MX500SSD1_2138E5D5061F";
    allowDiscards = true;
  };
  fileSystems."/nix" =
    { device = "/dev/mapper/crypt0";
      fsType = "btrfs";
      options = [ "device=/dev/mapper/crypt1" ];
      neededForBoot = true;
    };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # amd graphics
  hardware.graphics.extraPackages = with pkgs; [ amdvlk rocm-opencl-icd rocm-opencl-runtime ];
}
