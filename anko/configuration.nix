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

  # extra group for media-files
  users.groups.media-files = {
  };

  # Jellyfin media server, add it to media-files & make it persistent
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  users.users.jellyfin.extraGroups = [ "media-files" ];
  environment.persistence."/nix/persistent" = {
    directories = [
      # local Jellyfin instance
      { directory = "/var/lib/jellyfin"; mode = "0700"; user = "jellyfin"; }
    ];
  };
}
