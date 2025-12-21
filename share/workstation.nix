{ config, pkgs, ... }:

{
  # use networkd for my local machines
  networking.networkmanager.enable = false;
  networking.useDHCP = false;
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    networkConfig = {
      # start a DHCP Client for IPv4 Addressing/Routing
      DHCP = "ipv4";
      # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
      IPv6AcceptRA = true;
    };

    # make routing on this interface a dependency for network-online.target
    linkConfig.RequiredForOnline = "routable";
  };

  # EurKey layout
  services.xserver.xkb.layout = "eu";

  # auto update the machines at home
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  # Jellyfin media server
  services.jellyfin = {
    dataDir = "/data/home/jellyfin";
    enable = true;
    openFirewall = true;
  };
}
