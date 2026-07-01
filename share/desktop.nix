{ config, pkgs, ... }:
let
  cullmann-fonts = pkgs.callPackage "/data/nixos/packages/cullmann-fonts.nix" {};
in
{
  imports = [
      # flatpak configuration, makes only sense if we have some desktop around
      "/data/nixos/share/flatpak.nix"
  ];

  # enable the KDE Plasma Desktop Environment & Login Manager
  services.desktopManager.plasma6.enable = true;
  services.displayManager.plasma-login-manager.enable = true;

  # get gnupg to work
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-curses;

  # enable VirtualBox on the x86-64 machines
  virtualisation.virtualbox.host.enable = pkgs.stdenv.hostPlatform.isx86;

  # enable sound with PipeWire
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
    pulse.enable = true;

    # allow highres audio
    # check what
    #     grep Rates /proc/asound/card*/stream*
    # tells
    # we settle for 192000
    extraConfig.pipewire.hires = {
      "context.properties" = {
        "default.clock.rate" = 192000;
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 352800 384000 ];
      };
    };
  };

  # allow realtime
  security.rtkit.enable = true;

  # packages for the desktop system
  environment.systemPackages = with pkgs; [
    alsa-utils
    android-tools
    aspellDicts.de
    aspellDicts.en
    bitwise
    blender
    caligula
    castget
    clinfo
    cyanrip
    delta
    dig
    dmidecode
    duf
    dysk
    efibootmgr
    exfatprogs
    f2
    fdupes
    ffmpeg-full
    file
    flac
    flamegraph
    fzf
    gimp
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
    jmtpfs
    kdePackages.alpaka
    kdePackages.ark
    kdePackages.filelight
    kdePackages.k3b
    kdePackages.karousel
    kdePackages.kate
    kdePackages.kcachegrind
    kdePackages.kcalc
    kdePackages.keysmith
    kdePackages.kompare
    kdePackages.konsole
    kdePackages.okular
    kdePackages.partitionmanager
    keychain
    kid3
    krita
    lazygit
    libjxl
    libreoffice
    libva-utils
    libwebp
    lynis
    mesa-demos
    mtkclient
    nixos-install-tools
    nmap
    nvme-cli
    (perl.withPackages(ps: [ ps.ParallelForkManager ]))
    p7zip
    parted
    pciutils
    pdftk
    perf
    procs
    pulseaudio
    pwgen
    qmk
    restic
    ripgrep
    scc
    signify
    sniffnet
    ssh-audit
    sysstat
    tageditor
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
    xauth
    xhost
    xlsclients
  ];

  # allow keyboard configure tools to work
  hardware.keyboard.qmk.enable = true;

  # fonts for all users
  fonts = {
    # add default fonts
    enableDefaultPackages = true;

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

  # define the users we have on our systems
  users = {
    #
    # my main user
    #
    users.cullmann = {
      # home on persistent volume
      home = "/data/home/cullmann";

      # hard code UID for stability over machines
      uid = 1000;

      # normal user
      isNormalUser = true;

      # it's me :P
      description = "Christoph Cullmann";

      # allow for main user:
      #  - GrapheneOS install
      #  - Meshtastic flashing
      #  - KVM
      #  - VirtualBox
      #  - doas
      extraGroups = [ "adbusers" "dialout" "kvm" "vboxusers" "wheel" ];

      # init password
      hashedPassword = config.users.users.root.hashedPassword;

      # use fixed auth keys
      openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
    };

    #
    # sandbox for development
    #
    users.sandbox = {
      # home on persistent volume
      home = "/data/home/sandbox";

      # hard code UID for stability over machines
      # out of range of normal login users
      uid = 32001;

      # normal user
      isNormalUser = true;

      # sandbox user
      description = "Sandbox User";

      # use fixed auth keys
      openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
    };
  };

  # home manager settings
  home-manager = {
    # main user with extra settings
    users.cullmann = {
      # shared config
      imports = [ ./home.nix ];

      # enable keychain
      programs.keychain = {
        enable = true;
        enableZshIntegration = true;
        keys = [ "/data/home/cullmann/.ssh/id_ed25519" ];
      };
    };

    # sandbox user with extra settings
    users.sandbox = {
      # shared config
      imports = [ ./home.nix ];

      # create kde build setup
      home.file = {
        "projects/kde/.envrc" = {
          text = "use nix";
        };
        "projects/kde/cleanup.sh" = {
          text = (builtins.readFile "/data/nixos/projects/kde/cleanup.sh");
          executable = true;
        };
        "projects/kde/kdesrc-buildrc" = {
          text = (builtins.readFile "/data/nixos/projects/kde/kdesrc-buildrc");
        };
        "projects/kde/shell.nix" = {
          text = (builtins.readFile "/data/nixos/projects/kde/shell.nix");
        };
      };
    };
  };
}
