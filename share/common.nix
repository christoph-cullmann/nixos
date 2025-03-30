{ config, pkgs, ... }:
let
  impermanence = builtins.fetchTarball "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  cullmann-fonts = pkgs.callPackage "/data/nixos/packages/cullmann-fonts.nix" {};
  retroarchWithCores = (pkgs.retroarch.withCores (cores: with cores; [
    bsnes
    mgba
    quicknes
  ]));
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

  # install release
  system.stateVersion = "24.11";

  # atm all stuff is x86_64
  nixpkgs.hostPlatform = "x86_64-linux";

  # use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # allow md devices
  boot.swraid = {
    enable = true;
    mdadmConf = ''
      MAILADDR=christoph@cullmann.io
    '';
  };

  # my kernel parameters
  boot.kernelParams = [
    # Plymouth
    "quiet"
    "splash"

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

  # root file system in RAM
  fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
      neededForBoot = true;
      options = [ "defaults" "size=8G" "mode=755" ];
    };

  # my data
  fileSystems."/data" = {
    device = "/dev/mapper/crypt-system";
    fsType = "btrfs";
    options = [ "subvol=data" "noatime" "nodiscard" "commit=5" ];
    neededForBoot = true;
  };

  # the system
  fileSystems."/nix" = {
    device = "/dev/mapper/crypt-system";
    fsType = "btrfs";
    options = [ "subvol=nix" "noatime" "nodiscard" "commit=5" ];
    neededForBoot = true;
  };

  # tmp to not fill RAM
  fileSystems."/tmp" = {
    device = "/dev/mapper/crypt-system";
    fsType = "btrfs";
    options = [ "subvol=tmp" "noatime" "nodiscard" "commit=5" ];
    neededForBoot = true;
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

  # we want DRM support
  nixpkgs.config.chromium.enableWideVine = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alsa-utils
    aspellDicts.de
    aspellDicts.en
    bitwise
    blender
    btop
    chromium
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
    kdePackages.calligra
    kdePackages.filelight
    kdePackages.kate
    kdePackages.kcachegrind
    kdePackages.kcalc
    kdePackages.kio-extras
    kdePackages.kleopatra
    kdePackages.kmail
    kdePackages.konsole
    kdePackages.merkuro
    kdePackages.neochat
    kdePackages.okular
    kdePackages.tokodon
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
    okteta
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
    retroarchWithCores
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

  # olm is insecure
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  # run some stuff in a sandbox
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

      retroarch = {
        executable = "${retroarchWithCores}/bin/retroarch";
        profile = "${pkgs.firejail}/etc/firejail/retroarch.profile";
      };
    };
  };

  # chromium needs programs.firefox.enable here and systemPackages entry to have icon and work
  programs.chromium.enable = true;

  # firefox needs programs.firefox.enable here but no systemPackages entry to have icon and work
  programs.firefox.enable = true;

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

  # OpenGL, 32-bit for steam
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

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
    text = builtins.readFile "/data/nixos/secret/mail.secret";
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
    { groups = [ "wheel" ]; runAs = "sandbox-games"; noPass = true; }
    { groups = [ "wheel" ]; runAs = "sandbox-kde"; noPass = true; }
  ];
}
