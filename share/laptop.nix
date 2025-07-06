{ config, pkgs, ... }:

{
  # use NetworkManager, if we have WiFi, allows Plasma to manage connections
  # use iwd, only thing that works properly on e.g. Macs
  networking.networkmanager.enable = true;
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  # german laptop keyboard
  services.xserver.xkb.layout = "de";

  # enable proper power management
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;
}
