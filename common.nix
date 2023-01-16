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
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # zfs
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # persistent nix
  fileSystems."/nix" = {
    device = "zroot/nix";
    fsType = "zfs";
  };

  # persistent homes
  fileSystems."/home" = {
    device = "zroot/home";
    fsType = "zfs";
  };

  # non persistent root
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  # bind mount persistent nixos config, per host different
  fileSystems."/etc/nixos" = {
    device = "/home/cullmann/install/nixos/${config.networking.hostName}";
    options = [ "bind" ];
  };

  # bind mount persistent root home
  fileSystems."/root" = {
    device = "/home/root";
    options = [ "bind" ];
  };

  # some stuff is needed to early for environment.persistence
  environment.etc = {
    # stable host keys
    "ssh/ssh_host_rsa_key".source = "/nix/persistent/ssh_host_rsa_key";
    "ssh/ssh_host_rsa_key.pub".source = "/nix/persistent/ssh_host_rsa_key.pub";
    "ssh/ssh_host_ed25519_key".source = "/nix/persistent/ssh_host_ed25519_key";
    "ssh/ssh_host_ed25519_key.pub".source = "/nix/persistent/ssh_host_ed25519_key.pub";
  };

  # keep some stuff persistent
  environment.persistence."/nix/persistent" = {
    directories = [
      # systemd timers
      { directory = "/var/lib/systemd/timers"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }

      # clamav database
      { directory = "/var/lib/clamav"; user = "clamav"; group = "clamav"; mode = "u=rwx,g=rx,o=rx"; }
    ];
  };

  # allow all firmware
  hardware.enableAllFirmware = true;

  # use systemd-networkd
  networking.useDHCP = false;
  networking.useNetworkd = true;

  # ensure firewall is up
  networking.firewall.enable = true;

  # swap to RAM
  zramSwap.enable = true;

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

  # ensure we build all needed locales
  i18n.supportedLocales = ["en_US.UTF-8/UTF-8" "de_DE.UTF-8/UTF-8"];

  # ensure we see the journal on TTY12
  services.journald.console = "/dev/tty12";

  # keep power consumption and heat in check
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
  services.thermald.enable = true;

  # allow firmware updates
  services.fwupd.enable = true;

  # X11 settings, don't enable it, we use greetd
  services.xserver = {
    libinput.enable = true;

    # Configure keymap in X11
    layout = "eu";
    xkbVariant = "";

    # Enable the KDE Plasma Desktop Environment.
    desktopManager.plasma5.enable = true;
    desktopManager.plasma5.runUsingSystemd = true;
    desktopManager.plasma5.phononBackend = "vlc";

    # use GDM and Wayland
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.gdm.autoSuspend = false;
    displayManager.defaultSession = "plasmawayland";
  };

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
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

    # avoid that nix hogs all CPUs
    settings = {
      max-jobs = 1;
      cores = 4;
    };
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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    aspellDicts.de
    aspellDicts.en
    borgbackup
    bpytop
    clamav
    evtest # needs root permissions to run
    gitFull
    hunspellDicts.de_DE
    hunspellDicts.en_US
    lsof
    mailutils
    mc
    zsh
    zsh-powerlevel10k
  ];

  # allow keyboard configure tools to work
  services.udev.packages = [ pkgs.qmk-udev-rules pkgs.via ];

  # add ~/bin to PATH
  environment.homeBinInPath = true;

  # more fonts for all users
  fonts = {
    # some default fonts
    enableDefaultFonts = true;

    # more fonts
    fonts = with pkgs; [
      # nice monospaced font
      iosevka-bin

      # needed for powerlevel10k zsh stuff
      meslo-lgs-nf
    ];

    # tune fontconfig
    fontconfig = {
      # better default fonts
      defaultFonts = {
        monospace = ["Iosevka"];
      };
    };
  };

  # proper lutris gaming for 32-bit stuff
  hardware.opengl.driSupport32Bit = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "yes";
  };

  # virus scanner, we only want the updater running
  services.clamav.updater.enable = true;

  # try to ensure we can use our network printers
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  # let's get SSD status
  services.smartd.enable = true;

  # ensure cron and Co. can send mails
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    accounts = {
      default = {
        auth = true;
        tls = true;
        from = "noreply@home.local";
        host = "babylon2k.com";
        user = builtins.readFile "/home/root/nixos/mailuser";
        password = builtins.readFile "/home/root/nixos/mailpassword";
      };
    };
    defaults = {
      aliases = "/etc/aliases";
    };
  };

  environment.etc = {
    "aliases" = {
      text = ''
        root: christoph@cullmann.io
      '';
      mode = "0644";
    };
  };

  # allow the ZFS service to send mails
  services.zfs.zed.settings = {
    ZED_DEBUG_LOG = "/tmp/zed.debug.log";
    ZED_EMAIL_ADDR = [ "root" ];
    ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
    ZED_EMAIL_OPTS = "@ADDRESS@";

    ZED_NOTIFY_INTERVAL_SECS = 3600;
    ZED_NOTIFY_VERBOSE = true;

    ZED_USE_ENCLOSURE_LEDS = true;
    ZED_SCRUB_AFTER_RESILVER = true;
  };

  # use ZSH per default
  users.defaultUserShell = pkgs.zsh;

  # nice zsh config
  programs.zsh = {
    # zsh wanted
    enable = true;

    # some env vars I want in all of my shells
    shellInit = "export MOZ_ENABLE_WAYLAND=1; export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true;";

    # great prompt
    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme; if [ -f ~/.p10k.zsh ]; then source ~/.p10k.zsh; fi;";
  };

  # we want steam for gaming
  programs.steam.enable = true;

  # enable VirtualBox
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "cullmann" ];

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
    hashedPassword = builtins.readFile "/home/root/nixos/passwd";

    # use same keys as my main user
    openssh.authorizedKeys.keys = pkgs.lib.splitString "\n" (builtins.readFile "/home/cullmann/.ssh/authorized_keys");
  };

  home-manager.users.root = { pkgs, ... }: {
    # initial version
    home.stateVersion = "22.11";

    # sometimes doesn't work
    manual.manpages.enable = false;

    # generate the shell config
    programs.zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
      };
    };
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

    # allow sudo for my main user
    extraGroups = [ "wheel" ];

    # init password
    hashedPassword = builtins.readFile "/home/root/nixos/passwd";
  };

  home-manager.users.cullmann = { pkgs, ... }: {
    # initial version
    home.stateVersion = "22.11";

    # sometimes doesn't work
    manual.manpages.enable = false;

    # extra packages, stuff for work/kde/...
    home.packages = with pkgs; [
      alacritty
      ark
      chromium
      emacs
      falkon
      fdupes
      ffmpeg
      file
      firefox
      gimp-with-plugins
      gnome.gedit
      go
      hotspot
      hugo
      inetutils
      kate
      keychain
      keymapviz
      kitty
      libreoffice
      libwebp
      linuxKernel.packages.linux_latest_libre.perf
      marble
      neochat
      nmap
      okteta
      okular
      pciutils
      perf-tools
      pulseaudio
      qmk
      signal-desktop
      tcl
      texlive.combined.scheme-small
      tigervnc
      tk
      uim
      unrar
      unzip
      usbutils
      via
      vial
      vlc
      vscode
      xorg.xhost
    ];

    # enable direnv integration
    programs.direnv.enable = true;

    # nix-shell on drugs
    services.lorri.enable = true;

    # generate the shell config
    programs.zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -l";

        # system build/update/cleanup
        update = "sudo nixos-rebuild switch";
        upgrade = "sudo nixos-rebuild switch --upgrade";
        gc = "sudo nix-collect-garbage --delete-older-than 7d";
        verify = "sudo nix --extra-experimental-features nix-command store verify --all";
        optimize = "sudo nix --extra-experimental-features nix-command store optimise";

        # ssh around in the local network
        kuro = "ssh kuro.fritz.box";
        kuroroot = "ssh root@kuro.fritz.box";
        neko = "ssh neko.fritz.box";
        nekoroot = "ssh root@neko.fritz.box";
        liku = "ssh liku.fritz.box";
        likuroot = "ssh root@liku.fritz.box";
      };
    };

    # enable keychain
    programs.keychain = {
      enable = true;
      keys = [ "id_ed25519" ];
    };
  };

  #
  # sandbox user for games
  #

  users.users.sandbox = {
    # hard code UID for stability over machines
    uid = 1001;

    # normal user
    isNormalUser = true;

    # dummy sand box name for Windows games and Co.
    description = "Sand Box";
  };

  home-manager.users.sandbox = { pkgs, ... }: {
    # initial version
    home.stateVersion = "22.11";

    # sometimes doesn't work
    manual.manpages.enable = false;

    # extra packages, stuff for games
    home.packages = with pkgs; [
      alacritty
      ark
      lutris

      # retroarch with some emulators
      (retroarch.override {
        cores = [
          libretro.genesis-plus-gx
          libretro.snes9x
          libretro.beetle-psx-hw
        ];
      })
      libretro.genesis-plus-gx
      libretro.snes9x
      libretro.beetle-psx-hw

      sqlitebrowser
      unrar
      unzip
      xdotool
    ];

    # generate the shell config
    programs.zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
      };
    };
  };
}
