# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
      neededForBoot = true;
      options = [ "defaults" "size=8G" "mode=755" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-id/nvme-Seagate_FireCuda_530_ZP4000GM30013_7VS01VBM-part1";
      fsType = "vfat";
      neededForBoot = true;
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-id/nvme-Seagate_FireCuda_530_ZP4000GM30013_7VS01VBM-part2";
      fsType = "bcachefs";
      neededForBoot = true;
      options = [ "noatime" "nodiratime" ];
    };

  fileSystems."/data" =
    { device = "/dev/disk/by-id/nvme-Seagate_FireCuda_530_ZP4000GM30013_7VS01VBM-part3";
      fsType = "bcachefs";
      neededForBoot = true;
      options = [ "noatime" "nodiratime" ];
    };

  fileSystems."/home" =
    { device = "/data/home";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" ];
      depends = [ "/data" ];
    };

  fileSystems."/root" =
    { device = "/data/root";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" ];
      depends = [ "/data" ];
    };

  fileSystems."/etc/nixos" =
    { device = "/data/nixos/neko";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" ];
      depends = [ "/data" ];
    };

#   fileSystems."/home/cullmann/vms" =
#     { device = "/dev/disk/by-id/nvme-CT2000P5PSSD8_213330E4ED05";
#       fsType = "bcachefs";
#       neededForBoot = true;
#       options = [ "noatime" "nodiratime" ];
#       depends = [ "/home" ];
#     };
#
#   fileSystems."/home/cullmann/projects" =
#     { device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S69ENF0R846614L";
#       fsType = "bcachefs";
#       neededForBoot = true;
#       options = [ "noatime" "nodiratime" ];
#       depends = [ "/home" ];
#     };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
