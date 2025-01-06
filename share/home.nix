{
  # initial version
  home.stateVersion = "22.11";

  # ZSH with good config
  programs.zsh = {
    # ZSH on
    enable = true;

    # we want completion
    enableCompletion = true;

    # we want suggestions of already typed stuff
    autosuggestion.enable = true;

    # we want nice command highlighting
    syntaxHighlighting.enable = true;

    # better history
    history = {
      # save timestamps
      extended = true;

      # kill dupes over full history
      ignoreAllDups = true;

      # don't share history between sessions
      share = false;
    };

    # aliases
    shellAliases = {
      # system build/update/cleanup
      update = "doas nixos-rebuild boot";
      upgrade = "doas nixos-rebuild boot --upgrade";
      updatenow = "doas nixos-rebuild switch";
      upgradenow = "doas nixos-rebuild switch --upgrade";
      gc = "doas nix-collect-garbage --delete-older-than 7d";
      verify = "doas nix --extra-experimental-features nix-command store verify --all -s https://cache.nixos.org";
      optimize = "doas nix --extra-experimental-features nix-command store optimise";
      scrub = "doas btrfs scrub start -B /data";

      # list latest files last
      ltr = "eza -l -s modified";

      # ssh around in the local network
      beta = "ssh beta.fritz.box";
      betaroot = "ssh root@beta.fritz.box";
      bsd = "ssh bsd.fritz.box";
      bsdroot = "ssh root@bsd.fritz.box";
      mac = "ssh mac.fritz.box";
      macroot = "ssh root@mac.fritz.box";
      miku = "ssh miku.fritz.box";
      mikuroot = "ssh root@miku.fritz.box";
      mini = "ssh mini.fritz.box";
      miniroot = "ssh root@mini.fritz.box";
      moon = "ssh moon.babylon2k.com";
      moonroot = "ssh root@moon.babylon2k.com";
      neko = "ssh neko.fritz.box";
      nekoroot = "ssh root@neko.fritz.box";
    };
  };

  # nice prompt
  # https://starship.rs/config/
  # https://draculatheme.com/starship
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      command_timeout = 10000;
      aws.style = "bold #ffb86c";
      cmd_duration.style = "bold #f1fa8c";
      directory.style = "bold #50fa7b";
      hostname.style = "bold #ff5555";
      git_branch.style = "bold #ff79c6";
      git_status.style = "bold #ff5555";
      username = {
        format = "[$user]($style) on ";
        style_user = "bold #bd93f9";
      };
      character = {
        success_symbol = "[❯](bold #f8f8f2)";
        error_symbol = "[❯](bold #ff5555)";
      };
      directory = {
        truncation_length = 8;
        truncate_to_repo = false;
      };
    };
  };

  # nice cd
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd" "cd" ];
  };

  # integrate fuzzy search
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # better completion
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };

  # better ls, adds la and Co. aliases, too
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };

  # better cat
  programs.bat = {
    enable = true;
  };

  # better find
  programs.fd = {
    enable = true;
  };

  # https://github.com/nix-community/nix-direnv
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
