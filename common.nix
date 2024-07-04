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
      "/data/nixos/users.nix"
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
      options = [ "bind" "x-gvfs-hide" ];
      depends = [ "/data" ];
    };

  # bind mount to have root home
  fileSystems."/root" =
    { device = "/data/root";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" "x-gvfs-hide" ];
      depends = [ "/data" ];
    };

  # bind mount to have NixOS configuration, different per host
  fileSystems."/etc/nixos" =
    { device = "/data/nixos/${config.networking.hostName}";
      fsType = "none";
      neededForBoot = true;
      options = [ "bind" "x-gvfs-hide" ];
      depends = [ "/data" ];
    };

  # keep some stuff persistent
  environment.persistence."/nix/persistent" = {
    hideMounts = true;
    directories = [
      # systemd timers
      { directory = "/var/lib/systemd/timers"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }

      # alsa state for persistent sound settings
      { directory = "/var/lib/alsa"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }

      # nix tmp dir for rebuilds, don't fill our tmpfs root with that
      { directory = "/var/cache/nix"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }

      # NetworkManager connections
      { directory = "/etc/NetworkManager"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }
      { directory = "/var/lib/NetworkManager"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }
    ];
  };

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

  # enable greetd & the KDE Plasma Desktop Environment
  services.desktopManager.plasma6.enable = true;
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd '${pkgs.kdePackages.plasma-workspace}/libexec/plasma-dbus-run-session-if-needed ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland'";
      };
    };
  };

  # enable sound with PipeWire
  sound.enable = true;
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

  # move nix tmp directory off the tmpfs for large updates
  # for nixos-build we set that directory as tmp dir in the command
  systemd.services.nix-daemon = {
    environment = {
      # Location for temporary files
      TMPDIR = "/var/cache/nix";
    };
    serviceConfig = {
      # Create /var/cache/nix automatically on Nix Daemon start
      CacheDirectory = "nix";
    };
  };
  environment.variables.NIX_REMOTE = "daemon";

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
    clamav
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
    mc
    micro
    pkgs.kdePackages.neochat
    nixos-install-tools
    nmap
    nvme-cli
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

  # more fonts for all users
  fonts = {
    # default fonts
    enableDefaultPackages = true;

    # more fonts
    packages = with pkgs; [
      # add patched fonts for editor & terminal
      (nerdfonts.override { fonts = [ "Iosevka" "IosevkaTerm" ]; })

      # unicode capable fonts
      babelstone-han
      dejavu_fonts
      ipafont
      kochi-substitute
      noto-fonts
      noto-fonts-cjk
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-extra
      noto-fonts-emoji
    ];

    # tune fontconfig
    fontconfig = {
      # better default fonts
      defaultFonts = {
        monospace = ["IosevkaTerm Nerd Font Mono"];
        sansSerif = ["Noto Sans"];
        serif = ["Noto Serif"];
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

  # ensure cron and Co. can send mails
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    accounts = {
      default = {
        auth = true;
        tls = true;
        from = "christoph@cullmann.io";
        host = "moon.babylon2k.com";
        port = "587";
        user = builtins.readFile "/data/nixos/mailuser.secret";
        passwordeval = "cat /data/nixos/mailpassword.secret";
      };
    };
    defaults = {
      aliases = "/etc/aliases";
    };
  };

  # send mails on ZFS events
  services.zfs.zed = {
    settings = {
      ZED_DEBUG_LOG = "/tmp/zed.debug.log";
      ZED_EMAIL_ADDR = [ "root" ];
      ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
      ZED_EMAIL_OPTS = "@ADDRESS@";

      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true;

      ZED_USE_ENCLOSURE_LEDS = true;
      ZED_SCRUB_AFTER_RESILVER = true;
    };

    # this option does not work; will return error
    enableMail = false;
  };

  environment.etc = {
    "aliases" = {
      text = ''
        root: christoph@cullmann.io
      '';
      mode = "0644";
    };
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
