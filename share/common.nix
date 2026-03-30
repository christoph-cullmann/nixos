{ config, pkgs, ... }:
let
  impermanence = builtins.fetchTarball "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  #
  # stuff shared between home machines
  #

  # get impermanence working & include more shared parts
  imports = [
      # manage persistent files
      "${impermanence}/nixos.nix"

      # home manager for per user config
      "${home-manager}/nixos"
  ];

  # install release
  system.stateVersion = "25.05";

  # enable ZFS
  boot.supportedFilesystems = ["zfs"];

  # my kernel parameters
  boot.kernelParams = [
    # Plymouth
    "quiet"
    "splash"

    # don't check for split locks, for KVM and Co.
    "split_lock_detect=off"

    # fix igc 0000:0a:00.0 eno1: PCIe link lost, device now detached
    "pcie_port_pm=off"
    "pcie_aspm.policy=performance"

    # no hibernate for ZFS systems
    "nohibernate"

    # for the Apple stuff with Notch: use the space around it
    "apple_dcp.show_notch=1"
  ];

  # tweak ZFS
  # https://github.com/openzfs/zfs/issues/10253
  boot.extraModprobeConfig = ''
    # less scrub impact on other IO
    options zfs zfs_vdev_nia_credit=1
    options zfs zfs_vdev_scrub_max_active=1

    # less trim impact on other IO
    options zfs zfs_trim_queue_limit=5
  '';

  # setup some sysctl stuff
  boot.kernel.sysctl = {
    # allow dmesg for all users
    "kernel.dmesg_restrict" = 0;

    # allow proper perf usage
    "kernel.kptr_restrict" = 0;
    "kernel.perf_event_mlock_kb" = 1024;
    "kernel.perf_event_paranoid" = -1;

    # harden some stuff
    "dev.tty.ldisc_autoload" = 0;
    "fs.suid_dumpable" = 0;
    "kernel.sysrq" = 0;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    "net.ipv4.conf.all.accept_redirects" = false;
    "net.ipv4.conf.all.send_redirects" = false;
    "net.ipv4.conf.default.accept_redirects" = false;
    "net.ipv6.conf.all.accept_redirects" = false;
    "net.ipv6.conf.default.accept_redirects" = false;
  };

  # blacklist some stuff
  boot.blacklistedKernelModules = [
    # hardening
    "dccp"
    "sctp"
    "rds"
    "tipc"
  ];

  # use NetworkManager, if we have WiFi, allows Plasma to manage connections
  # use iwd, only thing that works properly on e.g. Macs
  networking.networkmanager.enable = true;
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  # enable proper power management
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;

  # swap to RAM, allow up to 10% of memory be used for that
  zramSwap.enable = true;
  zramSwap.memoryPercent = 10;

  # harden some services
  systemd.services.systemd-rfkill = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };

  systemd.services.systemd-journald = {
    serviceConfig = {
      UMask = 0077;
      PrivateNetwork = true;
      ProtectHostname = true;
      ProtectKernelModules = true;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;

  # use systemd early, we use boot.initrd.systemd.services.rollback to rollback /
  boot.initrd.systemd.enable = true;

  # works only on x86 machines, not on the Macs
  boot.loader.efi.canTouchEfiVariables = pkgs.stdenv.hostPlatform.isx86;

  # memcheck, works only on x86 machines
  boot.loader.systemd-boot.memtest86.enable = pkgs.stdenv.hostPlatform.isx86;

  # use the kmscon as console variant
  services.kmscon.enable = true;
  services.kmscon.useXkbConfig = true;

  # root file system, we will rollback that on boot
  fileSystems."/" = {
    device = "zpool/root";
    fsType = "zfs";
    neededForBoot = true;
  };

  # root rollback, see https://ryanseipp.com/post/nixos-encrypted-root/
  boot.initrd.systemd.services.rollback = {
    description = "Rollback root filesystem to a pristine state";
    wantedBy = ["initrd.target"];
    after = ["zfs-import-zpool.service"];
    before = ["sysroot.mount"];
    path = with pkgs; [zfs];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      zfs rollback -r zpool/root@blank && echo " >> >> Rollback Complete << <<"
    '';
  };

  # my data
  fileSystems."/data" = {
    device = "zpool/data";
    fsType = "zfs";
    neededForBoot = true;
  };

  # the system
  fileSystems."/nix" = {
    device = "zpool/nix";
    fsType = "zfs";
    neededForBoot = true;
  };

  # bind mount to have root home
  fileSystems."/root" = {
    device = "/data/root";
    fsType = "none";
    neededForBoot = true;
    options = [ "bind" "x-gvfs-hide" ];
    depends = [ "/data" ];
  };

  # bind mount to have NixOS configuration, different per host
  fileSystems."/etc/nixos" = {
    device = "/data/nixos/${config.networking.hostName}";
    fsType = "none";
    neededForBoot = true;
    options = [ "bind" "x-gvfs-hide" ];
    depends = [ "/data" ];
  };

  # keep some stuff persistent
  environment.persistence."/nix/persistent" = {
    hideMounts = true;
    directories = [
      # user and group mappings
      # Either "/var/lib/nixos" has to be persisted, or all users and groups must have a uid/gid specified. The following users are missing a uid
      "/var/lib/nixos"

      # systemd timers
      "/var/lib/systemd/timers"

      # alsa state for persistent sound settings
      "/var/lib/alsa"

      # NetworkManager connections
      "/etc/NetworkManager"
      "/var/lib/NetworkManager"

      # flatpak storage
      "/var/lib/flatpak"

      # ollama & Co. storage
      { directory = "/var/lib/private"; mode = "0700"; }

      # local Vaultwarden instance
      { directory = "/var/lib/vaultwarden"; mode = "0700"; user = "vaultwarden"; }
    ];
  };

  # ensure our data is not rotting
  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  # trim the stuff, we use SSDs
  services.zfs.trim.enable = true;

  # enable fast dbus
  services.dbus.implementation = "broker";

  # allow all firmware
  hardware.enableAllFirmware = true;

  # never the wireless variant, we use iwd, if at all
  networking.wireless.enable = pkgs.lib.mkForce false;

  # ensure firewall is up, allow ssh in
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # OpenSSH daemon config
  services.openssh = {
    # enable with public key only auth, start on demand only
    enable = true;
    startWhenNeeded = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;

    # only ed25519 keys, make them persistent
    hostKeys = [{
      path = "/nix/persistent/ssh_host_ed25519_key";
      type = "ed25519";
    }];

    # only safe ciphers & Co.
    settings.Ciphers = [ "aes256-gcm@openssh.com" ];
    settings.KexAlgorithms = [ "sntrup761x25519-sha512@openssh.com" ];
    settings.Macs = [ "hmac-sha2-512-etm@openssh.com" ];
  };

  # ensure ssh knows where xauth is for X11 forwarding
  programs.ssh.setXAuthLocation = true;

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

  # add all locales we use
  i18n.supportedLocales = ["de_DE.UTF-8/UTF-8" "en_US.UTF-8/UTF-8"];

  # no need to replace the kernel at runtime
  security.protectKernelImage = true;

  # package manager config
  nix = {
    # general settings
    settings = {
      # don't hog all cores, might OOM, too
      cores = 4;
      max-jobs = 4;

      # auto optimize the store
      auto-optimise-store = true;

      # enable new stuff
      experimental-features = "nix-command flakes";
    };

    # cleanup the store from time to time
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
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

  # allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # we want git with LFS support and Co.
  programs.git = {
    enable = true;
    lfs.enable = true;
    package = pkgs.gitFull;
    prompt.enable = true;
  };

  # add ~/bin to PATH
  environment.homeBinInPath = true;

  # ensure machine can send mails
  services.opensmtpd = {
    enable = true;
    setSendmail = true;
    serverConfiguration = ''
      table aliases file:/etc/mail/aliases
      table secrets file:/etc/mail/secrets
      listen on localhost
      action "local" mda "maildrop -d %{dest.user:lowercase}" virtual <aliases>
      action "relay" relay host smtps://smtp@moon.babylon2k.com auth <secrets> mail-from bot@babylon2k.com
      match for local action "local"
      match for any action "relay"
    '';
  };
  environment.etc."mail/aliases" = {
    text = "@ christoph@cullmann.io";
    mode = "0400";
  };
  environment.etc."mail/secrets" = {
    text = builtins.readFile "/data/nixos/secret/mail.secret";
    mode = "0400";
  };

  # send mails on ZFS events
  services.zfs.zed = {
    settings = {
      ZED_DEBUG_LOG = "/tmp/zed.debug.log";
      ZED_EMAIL_ADDR = [ "root" ];
      ZED_EMAIL_PROG = "/run/wrappers/bin/sendmail";
      ZED_EMAIL_OPTS = "@ADDRESS@";

      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true;

      ZED_USE_ENCLOSURE_LEDS = true;
      ZED_SCRUB_AFTER_RESILVER = true;
    };

    # this option does not work; will return error
    enableMail = false;
  };

  # basic packages we want on all machines
  environment.systemPackages = with pkgs; [
    btop
    lsof
    maildrop
    mailutils
    mc
    micro
    zoxide
    zsh
  ];

  # use ZSH per default
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];

  # needed for the ZSH completion
  environment.pathsToLink = [ "/share/zsh" ];

  # use micro as default terminal editor
  environment.variables.EDITOR = "micro";

  # use doas instead of sudo
  security.sudo.enable = false;
  security.doas.enable = true;
  security.doas.extraRules = [
    # wheel users are allowed to become all users
    # keep the environment, need that for many scripts
    { groups = [ "wheel" ]; noPass = false; keepEnv = true; persist = true; }
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
  };
}
