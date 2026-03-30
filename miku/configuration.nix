{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Machines that have a desktop env
      /data/nixos/share/desktop.nix

      # Shared config of all machines
      /data/nixos/share/common.nix
    ];

  # x86-64 machine
  nixpkgs.hostPlatform = "x86_64-linux";

  # our hostname
  networking.hostName = "miku";

  # hostid, important for ZFS pool
  networking.hostId = "4d00f481";

  # EurKey layout
  services.xserver.xkb.layout = "eu";

  # try local AI stuff
  services.ollama = {
    enable = true;

    # preload models, see https://ollama.com/library
    loadModels = [ "deepseek-coder" "deepseek-r1" "gemma3" "llama3.2" "llava" "mistral" ];
  };

  # local Vaultwarden
  services.vaultwarden.enable = true;

  # keep some stuff persistent for the miku services
  environment.persistence."/nix/persistent" = {
    directories = [
      # ollama & Co. storage
      { directory = "/var/lib/private"; mode = "0700"; }

      # local Vaultwarden instance
      { directory = "/var/lib/vaultwarden"; mode = "0700"; user = "vaultwarden"; }
    ];
  };
}
