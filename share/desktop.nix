{ config, pkgs, ... }:

{
  # boot splash
  boot.plymouth = {
    enable = true;
    theme = "hexa_retro";
    themePackages = [ pkgs.adi1090x-plymouth-themes ];
  };

  # enable the KDE Plasma Desktop Environment
  services.desktopManager.plasma6.enable = true;

  # enable the Ly login manager with proper KWallet integration
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "matrix";
      load = true;
      save = true;
      session_log = ".cache/ly-session.log";
    };
  };
  security.pam.services.ly.kwallet = {
    enable = true;
    forceRun = true;
    package = pkgs.kdePackages.kwallet-pam;
  };
}
