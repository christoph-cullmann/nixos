# based on https://www.reddit.com/r/NixOS/comments/1hzgxns/fully_declarative_flatpak_management_on_nixos/
# to list permissions: flatpak info --show-permissions ...
{ config, lib, pkgs, ... }:
let
  # default restrictions, applied globally and to all packs
  globalOverrides = "--nofilesystem=home --nofilesystem=host";

  # all wanted flatpak packages
  desiredFlatpaks = {
    # slicers needs accessed to shared folder with 3d stuff
    "com.bambulab.BambuStudio" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures --filesystem=/data/home/shared";
    "com.prusa3d.PrusaSlicer" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures --filesystem=/data/home/shared";

    # maximal sandboxed stuff for games
    "com.usebottles.bottles" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures";
    "com.valvesoftware.Steam" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures";

    # retrodeck needs access to games
    "net.retrodeck.retrodeck" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures --nofilesystem=xdg-data/Steam --nofilesystem=~/.steam --filesystem=~/Games";

    # maximal sandboxed browsers
    "com.vivaldi.Vivaldi" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures";
    "org.mozilla.firefox" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures";

    # maximal sandboxed messaging apps
    "org.kde.neochat" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures";
    "org.signal.Signal" = "--nofilesystem=xdg-music --nofilesystem=xdg-pictures";
  };

  # install helper, will set filesystem overrides
  install = lib.lists.foldl( str: app:
      str + pkgs.flatpak + "/bin/flatpak install --or-update -y flathub " + app + ";\n"
          + pkgs.flatpak + "/bin/flatpak override --reset " + app + ";\n"
          + pkgs.flatpak + "/bin/flatpak override " + globalOverrides + " " + (lib.attrsets.getAttrFromPath [ app ] desiredFlatpaks) + " " + app + ";\n"
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
