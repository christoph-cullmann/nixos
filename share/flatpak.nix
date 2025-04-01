# based on https://www.reddit.com/r/NixOS/comments/1hzgxns/fully_declarative_flatpak_management_on_nixos/
{ config, lib, pkgs, ... }:
let
  # all wanted flatpak packages
  desiredFlatpaks = {
    "com.valvesoftware.Steam" = "--nofilesystem=home --nofilesystem=xdg-pictures --nofilesystem=xdg-music";
    "com.vivaldi.Vivaldi" = "--nofilesystem=home --nofilesystem=xdg-pictures --nofilesystem=xdg-music";
    "io.github.ungoogled_software.ungoogled_chromium" = "--nofilesystem=home --nofilesystem=xdg-pictures --nofilesystem=xdg-music";
    "org.mozilla.firefox" = "--nofilesystem=home --nofilesystem=xdg-pictures --nofilesystem=xdg-music";
    "org.signal.Signal" = "--nofilesystem=home --nofilesystem=xdg-pictures --nofilesystem=xdg-music";
  };

  # install helper, will set filesystem overrides
  install = lib.lists.foldl( str: app:
      str + pkgs.flatpak + "/bin/flatpak install -y flathub " + app + ";\n"
          + pkgs.flatpak + "/bin/flatpak override --reset;\n"
          + pkgs.flatpak + "/bin/flatpak override --reset " + app + ";\n"
          + pkgs.flatpak + "/bin/flatpak override " + (lib.attrsets.getAttrFromPath [ app ] desiredFlatpaks) + " " + app + ";\n"
          + pkgs.flatpak + "/bin/flatpak override --show " + app + ";\n"
  ) "\n";
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
        if ! echo ${toString (builtins.attrNames desiredFlatpaks)} | ${pkgs.gnugrep}/bin/grep -q $installed; then
          echo "Removing $installed because it's not in the desiredFlatpaks list."
          ${pkgs.flatpak}/bin/flatpak uninstall -y --noninteractive $installed
        fi
      done

      # install or re-install the Flatpaks you DO want
      ${install (builtins.attrNames desiredFlatpaks)}

      # remove unused Flatpaks
      ${pkgs.flatpak}/bin/flatpak uninstall --unused -y

      # update all installed Flatpaks
      ${pkgs.flatpak}/bin/flatpak update -y
    '';
  };
}
