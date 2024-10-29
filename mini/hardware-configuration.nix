# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];

  # AMD microcode updates please
  hardware.cpu.amd.updateMicrocode = true;

  # amd graphics
  hardware.graphics.extraPackages = with pkgs; [ amdvlk rocmPackages.clr.icd ];

  # /boot efi partition to boot in UEFI mode
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1B9E-991C";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
    neededForBoot = true;
  };

  # encrypted system - on a md device
  boot.swraid.enable = true;
  boot.initrd.luks.devices."crypt-system" = {
    device = "/dev/disk/by-uuid/565695e2-a09b-412b-9f26-4da10402b967";
    allowDiscards = true;
    bypassWorkqueues = true;
  };
}
