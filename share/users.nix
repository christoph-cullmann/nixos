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
      hashedPassword = builtins.readFile "/nix/data/nixos/secret/password.secret";

      # use fixed auth keys
      openssh.authorizedKeys.keys = pkgs.lib.splitString "\n" (builtins.readFile "/nix/data/nixos/secret/authorized_keys.secret");
    };

    #
    # my main user
    #

    users.cullmann = {
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
  };

  # home manager settings
  home-manager = {
    # let home manager install stuff to /etc/profiles
    useUserPackages = true;

    # use global pkgs
    useGlobalPkgs = true;

    # use shared home manager settings
    users.root = import ./home.nix;
    users.cullmann = import ./home.nix;
  };
}
