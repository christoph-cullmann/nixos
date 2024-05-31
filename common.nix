{ config, pkgs, ... }:
let
  impermanence = builtins.fetchTarball "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  #
  # stuff shared between home machines
  #

  # get impermanence & home manager working
  imports = [
      # manage persistent files
      "${impermanence}/nixos.nix"

      # home manager for per user config
      "${home-manager}/nixos"
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

  # more responsive kernel
  boot.kernelPatches = [ {
        name = "enable RT_FULL";
        patch = null;
        extraConfig = ''
            PREEMPT y
            PREEMPT_BUILD y
            PREEMPT_VOLUNTARY n
            PREEMPT_COUNT y
            PREEMPTION y
            '';
     } ];

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
    ];
  };

  # ZFS services
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # enable fast dbus
  services.dbus.implementation = "broker";

  # allow all firmware
  hardware.enableAllFirmware = true;

  # ensure firewall is up, allow ssh and http in
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.logRefusedConnections = false;

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

  # EurKey layout everywhere
  services.xserver.xkb.layout = "eu";
  console.useXkbConfig = true;

  # enable SDDM & the KDE Plasma Desktop Environment
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";

  # other desktop environments for testing
  services.xserver.desktopManager.enlightenment.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.desktopManager.mate.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

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

  # auto update
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  # avoid suspend ever to be triggered
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # let home manager install stuff to /etc/profiles
  home-manager.useUserPackages = true;

  # use global pkgs
  home-manager.useGlobalPkgs = true;

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
    borgbackup
    btop
    calibre
    chromium
    clamav
    clinfo
    config.boot.kernelPackages.perf
    efibootmgr
    emacs
    fdupes
    ffmpeg
    file
    fzf
    pkgs.kdePackages.filelight
    gimp
    gitFull
    glxinfo
    go
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
    pkgs.kdePackages.konversation
    krita
    libjxl
    libreoffice
    libva-utils
    lsof
    mc
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
    pulseaudio
    pwgen
    qmk
    ssh-audit
    starship
    sysstat
    tcl
    texlive.combined.scheme-small
    tigervnc
    tk
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
      # includes nice developer fonts and used by powerlevel10k: https://www.nerdfonts.com/
      nerdfonts

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
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

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
  users.defaultUserShell = pkgs.zsh;
  environment.shells = with pkgs; [ zsh ];

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

  ###
  ### per user configuration below
  ###

  # all users and passwords are defined here
  users.mutableUsers = false;

  #
  # administrator
  #

  users.users.root = {
    # init password
    hashedPassword = builtins.readFile "/data/nixos/password.secret";

    # use fixed auth keys
    openssh.authorizedKeys.keys = pkgs.lib.splitString "\n" (builtins.readFile "/data/nixos/authorized_keys.secret");
  };

  home-manager.users.root = {
    # initial version
    home.stateVersion = "22.11";

    # zsh with some nice prompt
    programs.starship.enable = true;
    programs.zoxide.enable = true;
    programs.zsh.enable = true;
  };

  #
  # my main user
  #

  users.users.cullmann = {
    # hard code UID for stability over machines
    uid = 1000;

    # normal user
    isNormalUser = true;

    # it's me :P
    description = "Christoph Cullmann";

    # allow VirtualBox and sudo for my main user
    extraGroups = [ "vboxusers" "wheel" ];

    # init password
    hashedPassword = builtins.readFile "/data/nixos/password.secret";

    # use fixed auth keys
    openssh.authorizedKeys.keys = pkgs.lib.splitString "\n" (builtins.readFile "/data/nixos/authorized_keys.secret");
  };

  home-manager.users.cullmann = {
    # initial version
    home.stateVersion = "22.11";

    # zsh with some nice prompt and extra main user configuration
    programs.starship.enable = true;
    programs.zoxide.enable = true;
    programs.zsh = {
      # zsh with extras wanted
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      history.share = false;
      syntaxHighlighting.enable = true;

      # aliases
      shellAliases = {
        # system build/update/cleanup
        update = "sudo TMPDIR=/var/cache/nix nixos-rebuild boot";
        upgrade = "sudo TMPDIR=/var/cache/nix nixos-rebuild boot --upgrade";
        gc = "sudo nix-collect-garbage --delete-older-than 7d";
        verify = "sudo nix --extra-experimental-features nix-command store verify --all";
        optimize = "sudo nix --extra-experimental-features nix-command store optimise";

        # ssh around in the local network
        mac = "ssh mac.fritz.box";
        macroot = "ssh root@mac.fritz.box";
        mini = "ssh mini.fritz.box";
        miniroot = "ssh root@mini.fritz.box";
        neko = "ssh neko.fritz.box";
        nekoroot = "ssh root@neko.fritz.box";
      };
    };

    # enable keychain
    programs.keychain = {
      enable = true;
      keys = [ "id_ed25519" ];
    };

    # https://github.com/nix-community/nix-direnv
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
  };
}
