{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Shared config of all machines
      /data/nixos/share/common.nix
    ];

  # x86-64 machine
  nixpkgs.hostPlatform = "x86_64-linux";

  # our hostname
  networking.hostName = "anko";

  # hostid, important for ZFS pool
  networking.hostId = "598c1f34";

  # EurKey layout
  services.xserver.xkb.layout = "eu";

  # Squeezebox Client for itself
#   services.squeezelite = {
#     enable = true;
#     extraArguments = "-o hw:CARD=LT -s localhost";
#   };
#
#
  # Jellyfin media server, add it to media-files, too
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  users.users.jellyfin.extraGroups = [ "media-files" ];

  # Slim Server for Logitech Squeezebox Players, add it to media-files, too
  services.slimserver = {
    enable = true;
  };
  users.users.slimserver.extraGroups = [ "media-files" ];
  networking.firewall.allowedTCPPorts = [ 3483 9000 9090 ];
  networking.firewall.allowedUDPPorts = [ 3483 ];

  # keep some stuff persistent for the services
  environment.persistence."/nix/persistent" = {
    directories = [
      # local Jellyfin instance
      { directory = "/var/lib/jellyfin"; mode = "0700"; user = "jellyfin"; }

      # local Slim Server instance
      { directory = "/var/lib/slimserver"; mode = "0700"; user = "slimserver"; }
    ];
  };
}
