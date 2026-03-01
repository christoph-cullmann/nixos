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

  # Jellyfin media server, add it to media-files, too
  services.jellyfin = {
    dataDir = "/data/home/jellyfin";
    enable = true;
    openFirewall = true;
  };
  users.users.jellyfin.extraGroups = [ "media-files" ];

  # Slim Server for Logitech Squeezebox Players, add it to media-files, too
  services.slimserver = {
    dataDir = "/data/home/slimserver";
    enable = true;
  };
  users.users.slimserver.extraGroups = [ "media-files" ];
  networking.firewall.allowedTCPPorts = [ 3483 9000 9090 ];
  networking.firewall.allowedUDPPorts = [ 3483 ];
}
