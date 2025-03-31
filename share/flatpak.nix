# based on https://www.reddit.com/r/NixOS/comments/1hzgxns/fully_declarative_flatpak_management_on_nixos/
{ config, pkgs, ... }:
let
  # all wanted flatpak packages
  desiredFlatpaks = [
    "com.vivaldi.Vivaldi"
    "io.github.ungoogled_software.ungoogled_chromium"
    "org.mozilla.firefox"
    "org.signal.Signal"
  ];
in {
  # enable flatpak
  services.flatpak.enable = true;

  # update stuff on rebuild and boot
  system.activationScripts.flatpakManagement = {
    text = ''
      # ensure the Flathub repo is added
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

      # get currently installed Flatpaks
      installedFlatpaks=$(${pkgs.flatpak}/bin/flatpak list --app --columns=application)

      # remove any Flatpaks that are NOT in the desired list
      for installed in $installedFlatpaks; do
        if ! echo ${toString desiredFlatpaks} | ${pkgs.gnugrep}/bin/grep -q $installed; then
          echo "Removing $installed because it's not in the desiredFlatpaks list."
          ${pkgs.flatpak}/bin/flatpak uninstall -y --noninteractive $installed
        fi
      done

      # install or re-install the Flatpaks you DO want
      for app in ${toString desiredFlatpaks}; do
        echo "Ensuring $app is installed."
        ${pkgs.flatpak}/bin/flatpak install -y flathub $app
      done

      # remove unused Flatpaks
      ${pkgs.flatpak}/bin/flatpak uninstall --unused -y

      # update all installed Flatpaks
      ${pkgs.flatpak}/bin/flatpak update -y
    '';
  };
}
