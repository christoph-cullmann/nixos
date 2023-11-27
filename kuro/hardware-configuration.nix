# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=8G" "mode=755" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/263D-A89E";
      fsType = "vfat";
    };

  # system
  boot.initrd.luks.devices."crypt-system".device = "/dev/disk/by-uuid/f4af1379-93d2-4903-9fb5-5b767d733c66";

  fileSystems."/nix" =
    { device = "/dev/mapper/crypt-system";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "nodiratime" ];
    };

  fileSystems."/data" =
    { device = "/dev/mapper/crypt-system";
      fsType = "btrfs";
      options = [ "subvol=data" "noatime" "nodiratime" ];
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
    { device = "/data/nixos/kuro";
      fsType = "none";
      options = [ "bind" ];
    };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
