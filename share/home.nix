{
  # initial version
  home.stateVersion = "22.11";

  # my nushell config
  programs.nushell = {
    # we use nushell
    enable = true;

    # shell config
    extraConfig = ''
      $env.config = {
        history: {
          max_size: 100_000
          file_format: "sqlite"
          isolation: true
        }
        table: {
          mode: none
        }
      }
    '';

    # aliases
    shellAliases = {
      # system build/update/cleanup
      update = "sudo nixos-rebuild boot";
      upgrade = "sudo nixos-rebuild boot --upgrade";
      updatenow = "sudo nixos-rebuild switch";
      upgradenow = "sudo nixos-rebuild switch --upgrade";
      gc = "sudo nix-collect-garbage --delete-older-than 7d";
      verify = "sudo nix --extra-experimental-features nix-command store verify --all";
      optimize = "sudo nix --extra-experimental-features nix-command store optimise";

      # list latest files last
      ltr = "eza -l -s modified";

      # ssh around in the local network
      beta = "ssh beta.fritz.box";
      betaroot = "ssh root@beta.fritz.box";
      bsd = "ssh bsd.fritz.box";
      bsdroot = "ssh root@bsd.fritz.box";
      mac = "ssh mac.fritz.box";
      macroot = "ssh root@mac.fritz.box";
      mini = "ssh mini.fritz.box";
      miniroot = "ssh root@mini.fritz.box";
      neko = "ssh neko.fritz.box";
      nekoroot = "ssh root@neko.fritz.box";
    };
   };

  # nice prompt
  # https://starship.rs/config/
  # https://draculatheme.com/starship
  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
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
    enableNushellIntegration = true;
    options = [ "--cmd" "cd" ];
  };

  # better completion
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  # better ls, adds la and Co. aliases, too
  programs.eza = {
    enable = true;
    enableNushellIntegration = true;
  };

  # better cat
  programs.bat = {
    enable = true;
  };

  # better find
  programs.fd = {
    enable = true;
  };

  # enable keychain, we use the main user key
  programs.keychain = {
    enable = true;
    keys = [ "/home/cullmann/.ssh/id_ed25519" ];
  };

  # https://github.com/nix-community/nix-direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
