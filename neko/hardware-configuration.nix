# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "kvm-intel" ];

  # Intel microcode updates please
  hardware.cpu.intel.updateMicrocode = true;

  # intel graphics
  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver intel-compute-runtime ];

  # /boot efi partition to boot in UEFI mode
  fileSystems."/boot" =
    { device = "/dev/disk/by-id/nvme-Seagate_FireCuda_530_ZP4000GM30013_7VS01VBM-part1";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
      neededForBoot = true;
    };
}
