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

  # /boot efi partition to boot in UEFI mode
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/554C-161A";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
    neededForBoot = true;
  };

  # encrypted system
  boot.initrd.luks.devices."crypt-system" = {
    device = "/dev/disk/by-uuid/91f98284-b0fa-40b9-8a32-37f71968b2dd";
    allowDiscards = true;
    bypassWorkqueues = true;
  };
}
