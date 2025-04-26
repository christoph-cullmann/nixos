{ config, pkgs, ... }:
let
  impermanence = builtins.fetchTarball "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  cullmann-fonts = pkgs.callPackage "/data/nixos/packages/cullmann-fonts.nix" {};
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

      # flatpak configuration
      "/data/nixos/share/flatpak.nix"
  ];

  # install release
  system.stateVersion = "24.11";

  # atm all stuff is x86_64
  nixpkgs.hostPlatform = "x86_64-linux";

  # enable ZFS
  boot.supportedFilesystems = [ "zfs" ];

  # my kernel parameters
  boot.kernelParams = [
    # Plymouth
    "quiet"
    "splash"

    # no hibernate for ZFS systems
    "nohibernate"

    # make ARC fast
    "init_on_alloc=0"
    "init_on_free=0"

    # don't check for split locks, for KVM and Co.
    "split_lock_detect=off"

    # fix igc 0000:0a:00.0 eno1: PCIe link lost, device now detached
    "pcie_port_pm=off"
    "pcie_aspm.policy=performance"
  ];

  # setup some sysctl stuff
  boot.kernel.sysctl = {
    # allow dmesg for all users
    "kernel.dmesg_restrict" = 0;

    # allow proper perf usage
    "kernel.perf_event_mlock_kb" = 16777216;

    # harden some stuff
    "dev.tty.ldisc_autoload" = 0;
    "fs.suid_dumpable" = 0;
    "kernel.sysrq" = 0;
    "kernel.kptr_restrict" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    "net.ipv4.conf.all.accept_redirects" = false;
    "net.ipv4.conf.all.send_redirects" = false;
    "net.ipv4.conf.default.accept_redirects" = false;
    "net.ipv6.conf.all.accept_redirects" = false;
    "net.ipv6.conf.default.accept_redirects" = false;
  };

  # blacklist some stuff
  boot.blacklistedKernelModules = [
    # hardening
    "dccp"
    "sctp"
    "rds"
    "tipc"
  ];

  # harden some services
  systemd.services.systemd-rfkill = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };

  systemd.services.systemd-journald = {
    serviceConfig = {
      UMask = 0077;
      PrivateNetwork = true;
      ProtectHostname = true;
      ProtectKernelModules = true;
    };
  };

  # tweak ZFS
  boot.extraModprobeConfig = ''
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

  # tune the ZFS pool for NVMe
  system.activationScripts.zfsTuning = {
    text = ''
      # only one level of metadata caching
      ${pkgs.zfs}/bin/zfs set primarycache=all zpool
      ${pkgs.zfs}/bin/zfs set secondarycache=none zpool

      # use allow direct IO
      ${pkgs.zfs}/bin/zfs set direct=standard zpool
    '';
  };

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
  boot.plymouth = {
    enable = true;
    theme = "hexa_retro";
    themePackages = [ pkgs.adi1090x-plymouth-themes ];
  };

  # swap to RAM
  zramSwap.enable = true;

  # root file system, we will rollback that on boot
  fileSystems."/" = {
    device = "zpool/root";
    fsType = "zfs";
    neededForBoot = true;
  };

  # root rollback, see https://ryanseipp.com/post/nixos-encrypted-root/
  boot.initrd.systemd.services.rollback = {
    description = "Rollback root filesystem to a pristine state";
    wantedBy = ["initrd.target"];
    after = ["zfs-import-zpool.service"];
    before = ["sysroot.mount"];
    path = with pkgs; [zfs];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      zfs rollback -r zpool/root@blank && echo " >> >> Rollback Complete << <<"
    '';
  };

  # my data
  fileSystems."/data" = {
    device = "zpool/data";
    fsType = "zfs";
    neededForBoot = true;
  };

  # the system
  fileSystems."/nix" = {
    device = "zpool/nix";
    fsType = "zfs";
    neededForBoot = true;
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

      # flatpak storage
      "/var/lib/flatpak"

      # ollama storage
      "/var/lib/private/ollama"
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

  # enable SDDM & the KDE Plasma Desktop Environment with Wayland
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # enable sound with PipeWire
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
    pulse.enable = true;
  };

  # allow realtime
  security.rtkit.enable = true;

  # no need to replace the kernel at runtime
  security.protectKernelImage = true;

  # package manager config
  nix = {
    # general settings
    settings = {
      # don't hog all cores, might OOM, too
      cores = 4;
      max-jobs = 4;

      # auto optimize the store
      auto-optimise-store = true;

      # enable new stuff
      experimental-features = "nix-command flakes";
    };

    # cleanup the store from time to time
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    # https://github.com/nix-community/nix-direnv
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };

  # avoid suspend ever to be triggered
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alsa-utils
    aspellDicts.de
    aspellDicts.en
    bitwise
    blender
    btop
    clinfo
    config.boot.kernelPackages.perf
    delta
    dig
    dmidecode
    duf
    efibootmgr
    emacs
    f2
    fdupes
    ffmpeg
    file
    freecad
    fzf
    gimp
    glxinfo
    go
    gorilla-bin
    gptfdisk
    heaptrack
    hotspot
    hugo
    hunspellDicts.de_DE
    hunspellDicts.en_US
    hyfetch
    inetutils
    inkscape
    kdePackages.ark
    kdePackages.filelight
    kdePackages.kate
    kdePackages.kcachegrind
    kdePackages.kcalc
    kdePackages.konsole
    kdePackages.okular
    keychain
    kicad
    lazygit
    libjxl
    libreoffice
    libva-utils
    lsof
    lynis
    mailutils
    mc
    micro
    nixos-install-tools
    nmap
    nvme-cli
    procmail
    openscad
    p7zip
    parted
    pciutils
    pdftk
    procs
    pulseaudio
    pwgen
    qmk
    qsynth
    restic
    ripgrep
    scc
    ssh-audit
    sysstat
    tcl
    texlive.combined.scheme-small
    tigervnc
    tk
    tldr
    unrar
    unzip
    usbutils
    valgrind
    vlc
    vscodium
    vulkan-tools
    wayland-utils
    xorg.xhost
    xorg.xlsclients
    zoxide
    zsh
  ];

  # we want git with LFS support and Co.
  programs.git = {
    enable = true;
    lfs.enable = true;
    package = pkgs.gitFull;
    prompt.enable = true;
  };

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

    # system fonts
    packages = with pkgs; [
      # personal paid fonts
      # https://www.monolisa.dev/
      # https://www.lucasfonts.com/fonts/the-sans
      # https://www.lucasfonts.com/fonts/the-serif
      cullmann-fonts

      # font families with good unicode coverage as fallback
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-lgc-plus

      # emoji in Farbe und bunt
      noto-fonts-color-emoji

      # fonts collections for testing
      google-fonts

      # monospace fonts to test Kate, Konsole and Co.
      inconsolata
      maple-mono.truetype
      monaspace
      monocraft
      recursive
    ];

    # proper default config for fonts
    fontconfig = {
      # we use fontconfig
      enable = true;

      # use some proper default fonts
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [ "MonoLisa" "Noto Sans Mono" ];
        sansSerif = [ "TheSansOffice" "Noto Sans" ];
        serif = [ "TheSerifOffice" "Noto Serif" ];
      };

      # don't look like ancient X11
      antialias = true;

      # enable proper hinting
      hinting = {
        enable = true;
        style = "full";
        autohint = true;
      };

      # disable subpixel rendering to avoid color blurr
      subpixel = {
        rgba = "none";
        lcdfilter = "none";
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
      action "relay" relay host smtps://smtp@moon.babylon2k.com auth <secrets> mail-from bot@babylon2k.com
      match for local action "local"
      match for any action "relay"
    '';
  };
  environment.etc."mail/aliases" = {
    text = "@ christoph@cullmann.io";
    mode = "0400";
  };
  environment.etc."mail/secrets" = {
    text = builtins.readFile "/data/nixos/secret/mail.secret";
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

  # use doas instead of sudo
  security.sudo.enable = false;
  security.doas.enable = true;
  security.doas.extraRules = [
    # wheel users are allowed to become all users
    { groups = [ "wheel" ]; noPass = false; keepEnv = true; persist = true; }

    # wheel users can use sandbox stuff without password
    { groups = [ "wheel" ]; runAs = "sandbox-kde"; noPass = true; }
  ];

  # try local AI stuff
  services.ollama = {
    enable = true;

    # preload models, see https://ollama.com/library
    loadModels = [ "gemma3" "llama3.2" ];
  };
}
