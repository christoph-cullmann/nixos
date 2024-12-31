{ config, pkgs, ... }:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  # get home manager working
  imports = [
      # home manager for per user config
      "${home-manager}/nixos"
  ];

  # define the users we have on our systems
  users = {
    # all users and passwords are defined here
    mutableUsers = false;

    # default shell is ZSH
    defaultUserShell = pkgs.zsh;

    #
    # administrator
    #
    users.root = {
      # init password
      hashedPassword = builtins.readFile "/data/nixos/secret/password.secret";

      # use fixed auth keys
      openssh.authorizedKeys.keys = pkgs.lib.splitString "\n" (builtins.readFile "/data/nixos/secret/authorized_keys.secret");
    };

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

      # allow VirtualBox and sudo for my main user
      extraGroups = [ "vboxusers" "wheel" ];

      # init password
      hashedPassword = config.users.users.root.hashedPassword;

      # use fixed auth keys
      openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
    };

    #
    # sandbox for lutris and steam games and Co.
    #
    users.sandbox-games = {
      # home on persistent volume
      home = "/data/home/sandbox-games";

      # hard code UID for stability over machines
      # out of range of normal login users
      uid = 32000;

      # normal user
      isNormalUser = true;

      # sandbox user
      description = "Sandbox Games";

      # use fixed auth keys
      openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
    };

    #
    # sandbox for kde development
    #
    users.sandbox-kde = {
      # home on persistent volume
      home = "/data/home/sandbox-kde";

      # hard code UID for stability over machines
      # out of range of normal login users
      uid = 32001;

      # normal user
      isNormalUser = true;

      # sandbox user
      description = "Sandbox KDE";

      # use fixed auth keys
      openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
    };

    #
    # sandbox for 3d printing
    #
    users.sandbox-3d-printing = {
      # home on persistent volume
      home = "/data/home/sandbox-3d-printing";

      # hard code UID for stability over machines
      # out of range of normal login users
      uid = 32002;

      # normal user
      isNormalUser = true;

      # sandbox user
      description = "Sandbox 3D Printing";

      # use fixed auth keys
      openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
    };
  };

  # home manager settings
  home-manager = {
    # let home manager install stuff to /etc/profiles
    useUserPackages = true;

    # use global pkgs
    useGlobalPkgs = true;

    # root just with shared home manager settings
    users.root = {
      # shared config
      imports = [ ./home.nix ];
    };

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

      # MIDI
      services.fluidsynth = {
        enable = true;
        soundService = "pipewire-pulse";
      };
    };

    # games user with extra settings
    users.sandbox-games = {
      # shared config
      imports = [ ./home.nix ];

      # install gaming stuff
      home.packages = with pkgs; [
        lutris
        steam
        wineWowPackages.stable
        winetricks
      ];
    };

    # kde user with extra settings
    users.sandbox-kde = {
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

    # 3d printing user with extra settings
    users.sandbox-3d-printing = {
      # shared config
      imports = [ ./home.nix ];

      # install 3d printing stuff
      home.packages = with pkgs; [
        bambu-studio
        #orca-slicer
      ];
    };
  };
}
