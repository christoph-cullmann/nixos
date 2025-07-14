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
  system.stateVersion = "25.05";

  # enable ZFS
  boot.supportedFilesystems = ["zfs"];

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

    # no hibernate for ZFS systems
    "nohibernate"

    # for the Apple stuff with Notch: use the space around it
    "apple_dcp.show_notch=1"
  ];

  # setup some sysctl stuff
  boot.kernel.sysctl = {
    # allow dmesg for all users
    "kernel.dmesg_restrict" = 0;

    # allow proper perf usage
    "kernel.kptr_restrict" = 0;
    "kernel.perf_event_mlock_kb" = 1024;
    "kernel.perf_event_paranoid" = -1;

    # harden some stuff
    "dev.tty.ldisc_autoload" = 0;
    "fs.suid_dumpable" = 0;
    "kernel.sysrq" = 0;
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

  # swap to RAM, allow up to 10% of memory be used for that
  zramSwap.enable = true;
  zramSwap.memoryPercent = 10;

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

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;

  # use systemd early, we use boot.initrd.systemd.services.rollback to rollback /
  boot.initrd.systemd.enable = true;

  # works only on x86 machines, not on the Macs
  boot.loader.efi.canTouchEfiVariables = pkgs.stdenv.hostPlatform.isx86;

  # memcheck, works only on x86 machines
  boot.loader.systemd-boot.memtest86.enable = pkgs.stdenv.hostPlatform.isx86;

  # setup the console stuff early and use a nice font
  console.earlySetup = true;
  console.font = "${pkgs.spleen}/share/consolefonts/spleen-16x32.psfu";

  # boot splash
  boot.plymouth = {
    enable = true;
    theme = "hexa_retro";
    themePackages = [ pkgs.adi1090x-plymouth-themes ];
  };

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
  fileSystems."/root" = {
    device = "/data/root";
    fsType = "none";
    neededForBoot = true;
    options = [ "bind" "x-gvfs-hide" ];
    depends = [ "/data" ];
  };

  # bind mount to have NixOS configuration, different per host
  fileSystems."/etc/nixos" = {
    device = "/data/nixos/${config.networking.hostName}";
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

      # ollama & Co. storage
      { directory = "/var/lib/private"; mode = "0700"; }

      # local Vaultwarden instance
      { directory = "/var/lib/vaultwarden"; mode = "0700"; user = "vaultwarden"; }
    ];
    files = [
      # Ly last used user and Co.
      "/etc/ly/save.ini"
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

  # never the wireless variant, we use iwd, if at all
  networking.wireless.enable = false;

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

  # ensure ssh knows where xauth is for X11 forwarding
  programs.ssh.setXAuthLocation = true;

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

  # add all locales we use
  i18n.supportedLocales = ["de_DE.UTF-8/UTF-8" "en_US.UTF-8/UTF-8"];

  # use X11/wayland layout for console, too
  console.useXkbConfig = true;

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
    castget
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
    gnupg
    go
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
    kdePackages.keysmith
    kdePackages.konsole
    kdePackages.okular
    keychain
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
    signify
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
    vim
    vlc
    vscodium
    vulkan-tools
    wayland-utils
    xorg.xauth
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
      atkinson-hyperlegible-mono
      inconsolata
      maple-mono.truetype
      monaspace
      monocraft
      recursive
      spleen
    ]

    # add all nerd-fonts, very useful for testing, too
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

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

  # use powerlevel10k
  environment.etc."powerlevel10k/p10k.zsh".source = ./p10k.zsh;
  programs.zsh.promptInit = ''
      # use powerlevel10k
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source /etc/powerlevel10k/p10k.zsh

      # use powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '';

  # needed for the ZSH completion
  environment.pathsToLink = [ "/share/zsh" ];

  # use micro as default terminal editor
  environment.variables.EDITOR = "micro";

  # enable VirtualBox on the x86-64 machines
  virtualisation.virtualbox.host.enable = pkgs.stdenv.hostPlatform.isx86;
  virtualisation.virtualbox.host.enableKvm = true;
  virtualisation.virtualbox.host.enableHardening = false;
  virtualisation.virtualbox.host.addNetworkInterface = false;

  # allow GrapheneOS install
  programs.adb.enable = true;

  # use doas instead of sudo
  security.sudo.enable = false;
  security.doas.enable = true;
  security.doas.extraRules = [
    # wheel users are allowed to become all users
    # keep the environment, need that for many scripts
    { groups = [ "wheel" ]; noPass = false; keepEnv = true; persist = true; }
  ];

  # try local AI stuff
  services.ollama = {
    enable = true;

    # preload models, see https://ollama.com/library
    loadModels = [ "deepseek-coder" "deepseek-r1" "gemma3" "llama3.2" "llava" "mistral" ];
  };

  # get gnupg to work
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-curses;

  # local Vaultwarden
  services.vaultwarden.enable = true;
}
