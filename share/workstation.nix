{ config, pkgs, ... }:

{
  # just classic DHCP, wired only
  networking.networkmanager.enable = false;
  networking.useDHCP = true;

  # EurKey layout
  services.xserver.xkb.layout = "eu";

  # Jellyfin media server
  services.jellyfin = {
    dataDir = "/data/home/jellyfin";
    enable = true;
    openFirewall = true;
  };
}
