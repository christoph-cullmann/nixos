# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];

  # efi partition
  fileSystems."/boot" =
    { device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB1T0HBLR-000L2_S4DZNX0R362286-part1";
      fsType = "vfat";
      neededForBoot = true;
    };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # amd graphics
  hardware.graphics.extraPackages = with pkgs; [ amdvlk rocm-opencl-icd rocm-opencl-runtime ];
}