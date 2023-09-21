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

  # use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  # keep some stuff persistent
  environment.persistence."/nix/persistent" = {
    directories = [
      # systemd timers
      { directory = "/var/lib/systemd/timers"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }

      # clamav database
      { directory = "/var/lib/clamav"; user = "clamav"; group = "clamav"; mode = "u=rwx,g=rx,o=rx"; }
    ];
  };

  # ensure we scrub the btrfs sometimes
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  # allow all firmware
  hardware.enableAllFirmware = true;

  # use NetworkManager
  networking.useDHCP = false;
  networking.networkmanager.enable = true;

  # ensure firewall is up, allow ssh and http in
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.logRefusedConnections = false;

  # OpenSSH daemon config
  services.openssh = {
    # enable with public key only auth
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;

    # only ed25519 keys, make them persistent
    hostKeys = [{
      path = "/nix/persistent/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  # guard the ssh service
  services.sshguard.enable = true;

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

  # allow to have all locales
  i18n.supportedLocales = [ "all" ];

  # ensure we see the journal on TTY12
  services.journald.console = "/dev/tty12";

  # keep power consumption and heat in check
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
  services.thermald.enable = true;

  # allow firmware updates
  services.fwupd.enable = true;

  # X11 settings
  services.xserver = {
    libinput.enable = true;
    upscaleDefaultCursor = false;

    # Configure keymap in X11
    layout = "eu";
    xkbVariant = "";

    # Enable the KDE Plasma Desktop Environment.
    desktopManager.plasma5.enable = true;
    desktopManager.plasma5.runUsingSystemd = true;
    desktopManager.plasma5.phononBackend = "vlc";

    # use SDDM and Plasma Wayland
    enable = true;
    displayManager.sddm.enable = true;
    displayManager.defaultSession = "plasmawayland";
  };

  # enable sound with PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
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

    # avoid that nix hogs all CPUs
    settings = {
      max-jobs = 1;
      cores = 4;
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

  # let home manager install stuff to /etc/profiles
  home-manager.useUserPackages = true;

  # use global pkgs
  home-manager.useGlobalPkgs = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alacritty
    ark
    aspellDicts.de
    aspellDicts.en
    borgbackup
    btop
    chromium
    clamav
    clinfo
    config.boot.kernelPackages.perf
    efibootmgr
    filelight
    firefox
    gitFull
    glxinfo
    gptfdisk
    hunspellDicts.de_DE
    hunspellDicts.en_US
    libva-utils
    lsof
    mc
    nixos-install-tools
    nvme-cli
    p7zip
    parted
    unrar
    unzip
    vulkan-tools
    wayland-utils
    zsh
    zsh-powerlevel10k
  ];

  # allow keyboard configure tools to work
  hardware.keyboard.qmk.enable = true;

  # add ~/bin to PATH
  environment.homeBinInPath = true;

  # more fonts for all users
  fonts = {
    # more fonts
    packages = with pkgs; [
      # needed for powerlevel10k zsh stuff
      meslo-lgs-nf

      # unicode capable font
      noto-fonts
      noto-fonts-extra
      noto-fonts-emoji

      # nice mono spaced fonts
      fira-code
      iosevka-bin
      victor-mono
    ];

    # tune fontconfig
    fontconfig = {
      # better default fonts
      defaultFonts = {
        monospace = ["Iosevka"];
      };
    };
  };

  # 64-bit GL
  hardware.opengl.driSupport = true;

  # proper lutris gaming for 32-bit stuff
  hardware.opengl.driSupport32Bit = true;

  # virus scanner, we only want the updater running
  services.clamav.updater.enable = true;

  # try to ensure we can use our network LaserJet
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];

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
        port = "587";
        user = builtins.readFile "/data/nixos/mailuser.secret";
        password = builtins.readFile "/data/nixos/mailpassword.secret";
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

  # dconf is needed for gtk, see https://nixos.wiki/wiki/KDE
  programs.dconf.enable = true;

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
    hashedPassword = builtins.readFile "/data/nixos/password.secret";

    # use same keys as my main user
    openssh.authorizedKeys.keys = pkgs.lib.splitString "\n" (builtins.readFile "/home/cullmann/.ssh/authorized_keys");
  };

  home-manager.users.root = { pkgs, ... }: {
    # initial version
    home.stateVersion = "22.11";

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
    hashedPassword = builtins.readFile "/data/nixos/password.secret";
  };

  home-manager.users.cullmann = { pkgs, ... }: {
    # initial version
    home.stateVersion = "22.11";

    # extra packages, stuff for work/kde/...
    home.packages = with pkgs; [
      calibre
      emacs
      falkon
      fdupes
      ffmpeg
      file
      gimp
      go
      heaptrack
      hotspot
      hugo
      inetutils
      kate
      kcachegrind
      kcalc
      keychain
      kmail
      kompare
      konversation
      krita
      libjxl
      libreoffice
      neochat
      nmap
      okteta
      okular
      pciutils
      perf-tools
      pulseaudio
      qmk
      remmina
      signal-desktop
      tcl
      texlive.combined.scheme-small
      tigervnc
      tk
      tokodon
      usbutils
      valgrind
      vlc
      vscodium
      xorg.xhost
    ];

    # https://github.com/nix-community/nix-direnv
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;

    # reverse package search, https://github.com/nix-community/nix-index
    programs.nix-index.enable = true;

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

    # extra packages, stuff for games
    home.packages = with pkgs; [
      bottles
      lutris
      protonup-qt
      sqlitebrowser
      wine64
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
