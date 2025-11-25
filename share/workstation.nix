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

  #
  # support AirPlay devices in local network
  # https://wiki.nixos.org/wiki/PipeWire#AirPlay/RAOP_configuration
  #

  # avahi required for service discovery
  services.avahi.enable = true;

  services.pipewire = {
    # opens UDP ports 6001-6002
    raopOpenFirewall = true;

    extraConfig.pipewire = {
      "10-airplay" = {
        "context.modules" = [
          {
            name = "libpipewire-module-raop-discover";
          }
        ];
      };
    };
  };
}
