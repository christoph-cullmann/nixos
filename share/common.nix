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
      "/data/nixos/share/users.nix"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # use the latest kernel with ZFS support and enable that file system
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.supportedFilesystems = [ "zfs" ];

  # no hibernate for ZFS systems
  # don't check for split locks, for KVM and Co.
  boot.kernelParams = [ "nohibernate" "split_lock_detect=off" ];

  # tweak ZFS
  boot.extraModprobeConfig = ''
    options zfs zfs_arc_meta_limit_percent=75
    options zfs zfs_arc_min=134217728
    options zfs zfs_arc_max=4294967296
    options zfs zfs_txg_timeout=30
    options zfs zfs_vdev_scrub_min_active=1
    options zfs zfs_vdev_scrub_max_active=1
    options zfs zfs_vdev_sync_write_min_active=8
    options zfs zfs_vdev_sync_write_max_active=32
    options zfs zfs_vdev_sync_read_min_active=8
    options zfs zfs_vdev_sync_read_max_active=32
    options zfs zfs_vdev_async_read_min_active=8
    options zfs zfs_vdev_async_read_max_active=32
    options zfs zfs_vdev_async_write_min_active=8
    options zfs zfs_vdev_async_write_max_active=32
    options zfs zfs_vdev_def_queue_depth=128
  '';

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

  # nix store file system from encrypted ZFS
  fileSystems."/nix" =
    { device = "zpool/nix";
      fsType = "zfs";
      neededForBoot = true;
    };

  # data store file system from encrypted ZFS
  fileSystems."/data" =
    { device = "zpool/data";
      fsType = "zfs";
      neededForBoot = true;
    };

  # bind mount to have user homes
  fileSystems."/home" =
    { device = "/data/home";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" ];
      depends = [ "/data" ];
    };

  # bind mount to have root home
  fileSystems."/root" =
    { device = "/data/root";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" ];
      depends = [ "/data" ];
    };

  # bind mount to have NixOS configuration, different per host
  fileSystems."/etc/nixos" =
    { device = "/data/nixos/${config.networking.hostName}";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" ];
      depends = [ "/data" ];
    };

  # keep some stuff persistent
  environment.persistence."/nix/persistent" = {
    hideMounts = true;
    directories = [
      # tmp dir, don't fill our tmpfs root with that
      { directory = "/tmp"; user = "root"; group = "root"; mode = "1777"; }

      # systemd timers
      { directory = "/var/lib/systemd/timers"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }

      # alsa state for persistent sound settings
      { directory = "/var/lib/alsa"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }

      # NetworkManager connections
      { directory = "/etc/NetworkManager"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }
      { directory = "/var/lib/NetworkManager"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }
    ];
  };

  # kill the tmp content on reboots, we mount that to /nix/persistent to avoid memory fill-up
  boot.tmp.cleanOnBoot = true;

  # ensure our data is not rotting
  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  # trim the stuff, we use SSDs
  services.zfs.trim.enable = true;

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

  # avoid suspend ever to be triggered, ZFS dislikes that
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # save power
  powerManagement.enable = true;
  services.thermald.enable = true;

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
    krita
    lazygit
    libjxl
    libreoffice
    libva-utils
    lsof
    mailutils
    mc
    micro
    mission-center
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
    zoxide
    zsh
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
    fontDir.enable = true;

    # Nerd Fonts for the win
    packages = [ pkgs.nerdfonts ];

    # tune fontconfig
    fontconfig = {
      # better default fonts
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font Mono"];
        sansSerif = ["M+1 Nerd Font"];
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
    text = builtins.readFile "/data/nixos/mail.secret";
    mode = "0400";
  };

  # send mails on ZFS events
  services.zfs.zed = {
    settings = {
      ZED_DEBUG_LOG = "/tmp/zed.debug.log";
      ZED_EMAIL_ADDR = [ "root" ];
      ZED_EMAIL_PROG = "/run/wrappers/bin/sendmail";
      ZED_EMAIL_OPTS = "@ADDRESS@";

      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true;

      ZED_USE_ENCLOSURE_LEDS = true;
      ZED_SCRUB_AFTER_RESILVER = true;
    };

    # this option does not work; will return error
    enableMail = false;
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
  virtualisation.virtualbox.host.enableKvm = true;
  virtualisation.virtualbox.host.enableHardening = false;
  virtualisation.virtualbox.host.addNetworkInterface = false;

  # configure sudo
  security.sudo.execWheelOnly = true;
  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
