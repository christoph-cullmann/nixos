# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=8G" "mode=755" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F1C1-0271";
      fsType = "vfat";
    };

  # system
  boot.initrd.luks.devices."crypt-system".device = "/dev/disk/by-uuid/2dc54953-958b-4c5a-8454-21c0b1d16222";
  boot.initrd.luks.devices."crypt-system".allowDiscards = true;
  boot.initrd.luks.devices."crypt-system".bypassWorkqueues = true;

  # projects
  boot.initrd.luks.devices."crypt-projects".device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S69ENF0R846614L";
  boot.initrd.luks.devices."crypt-projects".allowDiscards = true;
  boot.initrd.luks.devices."crypt-projects".bypassWorkqueues = true;

  # vms
  boot.initrd.luks.devices."crypt-vms".device = "/dev/disk/by-id/nvme-CT2000P5PSSD8_213330E4ED05";
  boot.initrd.luks.devices."crypt-vms".allowDiscards = true;
  boot.initrd.luks.devices."crypt-vms".bypassWorkqueues = true;

  fileSystems."/nix" =
    { device = "/dev/mapper/crypt-system";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "compress=zstd" ];
    };

  fileSystems."/data" =
    { device = "/dev/mapper/crypt-system";
      fsType = "btrfs";
      options = [ "subvol=data" "noatime" "compress=zstd" ];
    };

  fileSystems."/home" =
    { device = "/data/home";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/root" =
    { device = "/data/root";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/etc/nixos" =
    { device = "/data/nixos/neko";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/home/cullmann/projects" =
    { device = "/dev/mapper/crypt-projects";
      fsType = "btrfs";
      options = [ "noatime" ];
    };

  fileSystems."/home/cullmann/vms" =
    { device = "/dev/mapper/crypt-vms";
      fsType = "btrfs";
      options = [ "noatime" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
