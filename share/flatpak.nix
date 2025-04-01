# based on https://www.reddit.com/r/NixOS/comments/1hzgxns/fully_declarative_flatpak_management_on_nixos/
{ config, lib, pkgs, ... }:
let
  # default restrictions, applied globally and to all packs
  globalOverrides = "--nofilesystem=home --nofilesystem=host";

  # all wanted flatpak packages
  desiredFlatpaks = {
    "com.valvesoftware.Steam" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures";
    "com.vivaldi.Vivaldi" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures";
    "io.github.ungoogled_software.ungoogled_chromium" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures";
    "org.mozilla.firefox" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures";
    "org.signal.Signal" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures";
  };

  # install helper, will set filesystem overrides
  install = lib.lists.foldl( str: app:
      str + pkgs.flatpak + "/bin/flatpak install -y flathub " + app + ";\n"
          + pkgs.flatpak + "/bin/flatpak override --reset " + app + ";\n"
          + pkgs.flatpak + "/bin/flatpak override " + globalOverrides + " " + app + ";\n" # just to be sure, is in the global settings already
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

      # setup global overrides, forbid most of the system
      ${pkgs.flatpak}/bin/flatpak override --reset
      ${pkgs.flatpak}/bin/flatpak override ${globalOverrides}

      # install or re-install the Flatpaks you DO want
      ${install (builtins.attrNames desiredFlatpaks)}

      # remove unused Flatpaks
      ${pkgs.flatpak}/bin/flatpak uninstall --unused -y

      # update all installed Flatpaks
      ${pkgs.flatpak}/bin/flatpak update -y
    '';
  };
}
