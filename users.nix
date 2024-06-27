{ config, pkgs, ... }:

{
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
      hashedPassword = builtins.readFile "/data/nixos/password.secret";

      # use fixed auth keys
      openssh.authorizedKeys.keys = pkgs.lib.splitString "\n" (builtins.readFile "/data/nixos/authorized_keys.secret");
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

  # use shared home manager settings for all users
  home-manager.users.root = import ./home.nix;
  home-manager.users.cullmann = import ./home.nix;
}
