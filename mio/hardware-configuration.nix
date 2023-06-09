# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/4196-36DD";
      fsType = "vfat";
    };

  boot.initrd.luks.devices."crypt-disk1".device = "/dev/disk/by-uuid/04638cc4-d719-4ef6-98d7-dd809032d608";
  boot.initrd.luks.devices."crypt-disk1".allowDiscards = true;
  boot.initrd.luks.devices."crypt-disk1".bypassWorkqueues = true;

  fileSystems."/nix" =
    { device = "/dev/mapper/crypt-disk1";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "compress=zstd" ];
    };

  fileSystems."/data" =
    { device = "/dev/mapper/crypt-disk1";
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
    { device = "/data/nixos/mio";
      fsType = "none";
      options = [ "bind" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
