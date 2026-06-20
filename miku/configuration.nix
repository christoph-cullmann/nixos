{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # Shared config of all machines
      /data/nixos/share/common.nix

      # Machines that have a desktop env
      /data/nixos/share/desktop.nix
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
    # turn ollama on
    enable = true;

    # preload models, see https://ollama.com/library
    loadModels = [ "gemma4:e4b" "granite4.1:8b" "qwen3.5:9b" ];

    # only keep modules listed in loadModels
    syncModels = true;

    # larger context to get qwen-code to work
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "65536";
    };
  };

  # local Vaultwarden
  services.vaultwarden.enable = true;

  # keep some stuff persistent for the services
  environment.persistence."/nix/persistent" = {
    directories = [
      # ollama & Co. storage
      { directory = "/var/lib/private"; mode = "0700"; }

      # local Vaultwarden instance
      { directory = "/var/lib/vaultwarden"; mode = "0700"; user = "vaultwarden"; }
    ];
  };
}
