{
  # initial version
  home.stateVersion = "22.11";

  # ZSH with some nice prompt and extra main user configuration
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
      updatenow = "sudo TMPDIR=/var/cache/nix nixos-rebuild switch";
      upgradenow = "sudo TMPDIR=/var/cache/nix nixos-rebuild switch --upgrade";
      gc = "sudo nix-collect-garbage --delete-older-than 7d";
      verify = "sudo nix --extra-experimental-features nix-command store verify --all";
      optimize = "sudo nix --extra-experimental-features nix-command store optimise";

      # overwrite some tools
      cat = "bat";
      ls = "lsd";

      # ssh around in the local network
      mac = "ssh mac.fritz.box";
      macroot = "ssh root@mac.fritz.box";
      mini = "ssh mini.fritz.box";
      miniroot = "ssh root@mini.fritz.box";
      neko = "ssh neko.fritz.box";
      nekoroot = "ssh root@neko.fritz.box";
    };
  };

  # nice prompt
  programs.oh-my-posh = {
    enable = true;
    useTheme = "slim";
  };

  # nice cd
  programs.zoxide = {
    enable = true;
    options = [ "--cmd" "cd" ];
  };

  # integrate fuzzy search
  programs.fzf = {
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
