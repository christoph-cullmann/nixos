# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:
let
  impermanence = builtins.fetchTarball "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
  

      # manage persistent files
      "${impermanence}/nixos.nix"

      # home manager for per user config
      "${home-manager}/nixos"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  # use a high resolution
  boot.loader.systemd-boot.consoleMode = "max";

  # use systemd early
  boot.initrd.systemd.enable = true;

  # setup the console stuff early
  console.earlySetup = true;

  networking.hostName = "mio"; # Define your hostname.

  # keep some stuff persistent
  environment.persistence."/nix/persistent" = {
    directories = [
      # NetworkManager connections
      { directory = "/etc/NetworkManager"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }
      { directory = "/var/lib/NetworkManager"; user = "root"; group = "root"; mode = "u=rwx,g=rx,o=rx"; }
    ];
  };

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
    layout = "de";
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

    # we want some experimental features like nix search
    extraOptions = ''experimental-features = nix-command flakes'';
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
    btop
    clamav
    gitFull
    hunspellDicts.de_DE
    hunspellDicts.en_US
    lsof
    mc
    woeusb
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
    fonts = with pkgs; [
      # nice mono spaced font
      iosevka-bin

      # needed for powerlevel10k zsh stuff
      meslo-lgs-nf

      # unicode capable font
      noto-fonts
      noto-fonts-extra
      noto-fonts-emoji
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

  # let's get SSD status
  services.smartd.enable = true;

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
    hashedPassword = builtins.readFile "/data/nixos/password.secret";
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
      calibre
      chromium
      emacs
      falkon
      fdupes
      ffmpeg
      file
      firefox
      gimp
      go
      hugo
      inetutils
      kate
      kcalc
      keychain
      konversation
      krita
      libjxl
      libreoffice
      linuxKernel.packages.linux_latest_libre.perf
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
      unrar
      unzip
      usbutils
      via
      vial
      vlc
      vscodium
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


  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
