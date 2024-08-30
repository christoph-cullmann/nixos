{ config, pkgs, ... }:
let
  impermanence = builtins.fetchTarball "https://github.com/nix-community/impermanence/archive/master.tar.gz";
in
{
  #
  # stuff shared between home machines
  #

  # get impermanence working & include more shared parts
  imports = [
      # manage persistent files
      "${impermanence}/nixos.nix"

      # our users
      "/nix/data/nixos/share/users.nix"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # my kernel parameters
  boot.kernelParams = [
    # don't check for split locks, for KVM and Co.
    "split_lock_detect=off"

    # avoid that my USB stuff sleeps
    "usbcore.autosuspend=-1"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # use a high resolution
  boot.loader.systemd-boot.consoleMode = "max";

  # we want to be able to do a memtest
  boot.loader.systemd-boot.memtest86.enable = true;

  # use systemd early
  boot.initrd.systemd.enable = true;

  # setup the console stuff early
  console.earlySetup = true;

  # boot splash
  boot.plymouth.enable = true;

  # swap to RAM
  zramSwap.enable = true;

  # root file system in RAM
  fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
      neededForBoot = true;
      options = [ "defaults" "size=8G" "mode=755" ];
    };

  # tmp on /nix to not fill RAM
  fileSystems."/tmp" =
    { device = "/nix/tmp";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" ];
      depends = [ "/nix" ];
    };

  # bind mount to have user homes
  fileSystems."/home" =
    { device = "/nix/data/home";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" ];
      depends = [ "/nix" ];
    };

  # bind mount to have root home
  fileSystems."/root" =
    { device = "/nix/data/root";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" ];
      depends = [ "/nix" ];
    };

  # bind mount to have NixOS configuration, different per host
  fileSystems."/etc/nixos" =
    { device = "/nix/data/nixos/${config.networking.hostName}";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" ];
      depends = [ "/nix" ];
    };

  # keep some stuff persistent
  environment.persistence."/nix/persistent" = {
    hideMounts = true;
    directories = [
      # user and group mappings
      # Either "/var/lib/nixos" has to be persisted, or all users and groups must have a uid/gid specified. The following users are missing a uid
      "/var/lib/nixos"

      # systemd timers
      "/var/lib/systemd/timers"

      # alsa state for persistent sound settings
      "/var/lib/alsa"

      # NetworkManager connections
      "/etc/NetworkManager"
      "/var/lib/NetworkManager"
    ];
  };

  # kill the tmp content on reboots, we mount that to /nix/persistent to avoid memory fill-up
  boot.tmp.cleanOnBoot = true;

  # enable fast dbus
  services.dbus.implementation = "broker";

  # allow all firmware
  hardware.enableAllFirmware = true;

  # use NetworkManager, works well for WiFi, too
  networking.networkmanager.enable = true;

  # ensure firewall is up, allow ssh in
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # OpenSSH daemon config
  services.openssh = {
    # enable with public key only auth, start on demand only
    enable = true;
    startWhenNeeded = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;

    # only ed25519 keys, make them persistent
    hostKeys = [{
      path = "/nix/persistent/ssh_host_ed25519_key";
      type = "ed25519";
    }];

    # only safe ciphers & Co.
    settings.Ciphers = [ "aes256-gcm@openssh.com" ];
    settings.KexAlgorithms = [ "sntrup761x25519-sha512@openssh.com" ];
    settings.Macs = [ "hmac-sha2-512-etm@openssh.com" ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # default locale is English US
  i18n.defaultLocale = "en_US.UTF-8";

  # use German stuff for sorting/date/....
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # allow to have all locales
  i18n.supportedLocales = [ "all" ];

  # use X11/wayland layout for console, too
  console.useXkbConfig = true;

  # enable SDDM & the KDE Plasma Desktop Environment with Wayland
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # enable sound with PipeWire
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  # allow realtime
  security.rtkit.enable = true;

  # no need to replace the kernel at runtime
  security.protectKernelImage = true;

  # package manager config
  nix = {
    # auto optimize the store
    settings.auto-optimise-store = true;

    # cleanup the store from time to time
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    # enable new stuff
    settings.experimental-features = "nix-command flakes";

    # https://github.com/nix-community/nix-direnv
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };

  # auto update
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  # trim the disks weekly
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # scrub the disks weekly
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  # avoid suspend ever to be triggered
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # we want DRM support
  nixpkgs.config.chromium.enableWideVine = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pkgs.kdePackages.ark
    aspellDicts.de
    aspellDicts.en
    bitwise
    borgbackup
    btop
    calibre
    chromium
    clinfo
    config.boot.kernelPackages.perf
    delta
    duf
    efibootmgr
    emacs
    f2
    fdupes
    ffmpeg
    file
    fzf
    pkgs.kdePackages.filelight
    gimp
    gitFull
    glxinfo
    go
    gorilla-bin
    gptfdisk
    heaptrack
    hotspot
    hugo
    hunspellDicts.de_DE
    hunspellDicts.en_US
    inetutils
    inkscape
    pkgs.kdePackages.kate
    pkgs.kdePackages.kcachegrind
    pkgs.kdePackages.kcalc
    keychain
    pkgs.kdePackages.kmail
    pkgs.kdePackages.konsole
    lazygit
    libjxl
    libreoffice
    libva-utils
    lsof
    mailutils
    mc
    pkgs.kdePackages.merkuro
    micro
    mission-center
    mplayer
    pkgs.kdePackages.neochat
    nixos-install-tools
    nmap
    nvme-cli
    procmail
    okteta
    pkgs.kdePackages.okular
    p7zip
    parted
    pciutils
    pdftk
    procs
    pulseaudio
    pwgen
    qmk
    ripgrep
    scc
    ssh-audit
    sysstat
    tcl
    texlive.combined.scheme-small
    tigervnc
    tk
    tldr
    pkgs.kdePackages.tokodon
    unrar
    unzip
    usbutils
    valgrind
    vlc
    vscodium
    vulkan-tools
    wayland-utils
    xorg.xlsclients
    zoxide
    zsh
  ];

  # olm is insecure
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  # run browsers in a sandbox
  programs.firejail = {
    enable = true;

    wrappedBinaries = {
      chromium = {
        executable = "${pkgs.lib.getBin pkgs.chromium}/bin/chromium";
        profile = "${pkgs.firejail}/etc/firejail/chromium.profile";
      };

      firefox = {
        executable = "${pkgs.lib.getBin pkgs.firefox}/bin/firefox";
        profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
      };

      signal-desktop = {
        executable = "${pkgs.signal-desktop}/bin/signal-desktop";
        profile = "${pkgs.firejail}/etc/firejail/signal-desktop.profile";
      };
    };
  };

  # chromium needs programs.firefox.enable here and systemPackages entry to have icon and work
  programs.chromium.enable = true;

  # firefox needs programs.firefox.enable here but no systemPackages entry to have icon and work
  programs.firefox.enable = true;

  # Flatpak to sandbox Steam, Bottles and Co.
  #
  # flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  # flatpak install --user flathub com.usebottles.bottles
  # flatpak install --user flathub com.valvesoftware.Steam
  # flatpak update --user
  #
  services.flatpak.enable = true;

  # allow keyboard configure tools to work
  hardware.keyboard.qmk.enable = true;

  # add ~/bin to PATH
  environment.homeBinInPath = true;

  # fonts for all users
  fonts = {
    # no default fonts
    enableDefaultPackages = false;

    # ensure we have an emulated global fontdir
    fontDir = {
      enable = true;
      decompressFonts = true;
    };

    # get a small list of curated fonts
    packages = with pkgs; [
      # font families with good unicode coverage as fallback
      ibm-plex
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-lgc-plus

      # emoji in Farbe und bunt
      noto-fonts-color-emoji
    ];

    # use some proper default fonts
    fontconfig = {
      enable = true;
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [ "MonoLisa" "IBM Plex Mono" "Noto Sans Mono" ];
        sansSerif = [ "Bespoke Sans Variable" "IBM Plex Sans" "Noto Sans" ];
        serif = [ "Bespoke Serif Variable" "IBM Plex Serif" "Noto Serif" ];
      };

      # fixes pixelation
      antialias = true;

      # fixes antialiasing blur
      hinting = {
        enable = true;
        style = "full";
        autohint = true;
      };

      # makes it bolder
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
    };
  };

  # OpenGL
  hardware.graphics.enable = true;

  # try to ensure we can use our network LaserJet
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];

  # dconf is needed for gtk, see https://nixos.wiki/wiki/KDE
  programs.dconf.enable = true;

  # https://nixos.wiki/wiki/Chromium - Wayland support on
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # ensure machine can send mails
  services.opensmtpd = {
    enable = true;
    setSendmail = true;
    serverConfiguration = ''
      table aliases file:/etc/mail/aliases
      table secrets file:/etc/mail/secrets
      listen on localhost
      action "local" mda "procmail -f -" virtual <aliases>
      action "relay" relay host smtps://smtp@moon.babylon2k.com auth <secrets> mail-from bot@cullmann.io
      match for local action "local"
      match for any action "relay"
    '';
  };
  environment.etc."mail/aliases" = {
    text = "@ christoph@cullmann.io";
    mode = "0400";
  };
  environment.etc."mail/secrets" = {
    text = builtins.readFile "/nix/data/nixos/mail.secret";
    mode = "0400";
  };

  # use ZSH per default
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];

  # needed for the ZSH completion
  environment.pathsToLink = [ "/share/zsh" ];

  # use micro as default terminal editor
  environment.variables.EDITOR = "micro";

  # enable VirtualBox
  virtualisation.virtualbox.host.enable = true;
  #virtualisation.virtualbox.host.enableKvm = true;
  virtualisation.virtualbox.host.enableHardening = false;
  virtualisation.virtualbox.host.addNetworkInterface = false;

  # configure sudo
  security.sudo.execWheelOnly = true;
  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
