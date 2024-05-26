# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "kvm-intel" ];

  # use the right soundcard
  boot.extraModprobeConfig = ''
    options snd_hda_intel enable=0,1
  '';

  # don't check for split locks, for KVM and Co.
  boot.kernelParams = [ "split_lock_detect=off" ];

  # system
  boot.initrd.luks.devices."crypt-system".device = "/dev/disk/by-id/nvme-Seagate_FireCuda_530_ZP4000GM30013_7VS01VBM-part2";

  # efi partition
  fileSystems."/boot" =
    { device = "/dev/disk/by-id/nvme-Seagate_FireCuda_530_ZP4000GM30013_7VS01VBM-part1";
      fsType = "vfat";
      neededForBoot = true;
    };

  # vms
  boot.initrd.luks.devices."crypt-vms".device = "/dev/disk/by-id/nvme-CT2000P5PSSD8_213330E4ED05";
  fileSystems."/home/cullmann/vms" =
    { device = "/dev/mapper/crypt-vms";
      fsType = "btrfs";
      neededForBoot = true;
      options = [ "noatime" "nodiratime" ];
      depends = [ "/home" ];
    };

  # projects
  boot.initrd.luks.devices."crypt-projects".device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S69ENF0R846614L";
  fileSystems."/home/cullmann/projects" =
    { device = "/dev/mapper/crypt-projects";
      fsType = "btrfs";
      neededForBoot = true;
      options = [ "noatime" "nodiratime" ];
      depends = [ "/home" ];
    };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
