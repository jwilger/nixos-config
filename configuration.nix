{inputs, pkgs, lib, ...}: let
  pkgs-unstable = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ./hardware-configuration.nix
  ];

  hardware.graphics = {
    package = pkgs-unstable.mesa.drivers;
    package32 = pkgs-unstable.pkgsi686Linux.mesa.drivers;
    enable32Bit = true;
  };

  stylix = {
    enable = true;
    image = ./wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
    polarity = "dark";
  };

  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      trusted-users = root jwilger
    '';
  };

  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };
  boot = {
    plymouth = {
      enable = true;
      theme = lib.mkForce "rings";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "rings" ];
        })
      ];
    };
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;
    # Bootloader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelParams = [ "quiet" "splash" "boot.shell_on_fail" "loglevel=3" "rd.systemd.show_status=false" "rd.udev.log_level=3" "udev.log_priority=3" ];
    loader.timeout = 0;
  };

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  virtualisation = {
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };

  services = {
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd 'uwsm start default'";
          user = "greeter";
        };
      };
    };
    interception-tools =
    let
      itools = pkgs.interception-tools;
      itools-caps = pkgs.interception-tools-plugins.caps2esc;
    in
    {
      enable = true;
      plugins = [ itools-caps ];
      udevmonConfig = pkgs.lib.mkDefault ''
        - JOB: "${itools}/bin/intercept -g $DEVNODE | ${itools-caps}/bin/caps2esc -m 0 | ${itools}/bin/uinput -d $DEVNODE"
          DEVICE:
            EVENTS:
              EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
      '';
    };
    
    fstrim.enable = true;

    gnome = {
      gnome-keyring = {
        enable = true;
      };
    };

    printing = {
      enable = true;
      drivers = [pkgs.brlaser];
    };

    pipewire = {
      enable = true;
      audio.enable = true;
      wireplumber.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
    };

    # List services that you want to enable:
    openssh.enable = true;
    fail2ban.enable = true;
  };

  security = {
    rtkit.enable = true;
    pam.services.greetd.enableGnomeKeyring = true;
  };
  
  users = {
    users.jwilger = {
      isNormalUser = true;
      description = "John Wilger";
      extraGroups = ["networkmanager" "wheel" "docker"];
      shell = pkgs.zsh;
      home = "/home/jwilger";
      group = "jwilger";
      createHome = true;
      linger = true;
    };

    groups.jwilger = {};
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    kitty
    home-manager
    docker-client
    neovim
    pipewire
    wireplumber
    grim
    slurp
    solaar
    firefoxpwa
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.variables.XDG_RUNTIME_DIR = "/run/user/$UID";

  fonts.fontconfig.useEmbeddedBitmaps = true;
  fonts.packages = with pkgs; [
    material-design-icons
    powerline-fonts
    powerline-symbols
    noto-fonts-color-emoji
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      xwayland = {
        enable = true;
      };
      withUWSM = true;
    };

    hyprlock.enable = true;
    
    nix-ld = {
      enable = true;
    };

    mtr.enable = true;

    _1password = {
      enable = true;
    };

    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["jwilger"];
    };

    firefox = {
      enable = true;
      package = pkgs.firefox;
      nativeMessagingHosts.packages = [pkgs.firefoxpwa];
    };

    zsh.enable = true;
  };

  networking = {
    hostName = "gregor"; # Define your hostname.
    networkmanager.enable = true;
    nftables.enable = true;
    firewall.allowedTCPPorts = [ 80 443 ];
  };

  system.stateVersion = "24.11"; # Did you read the comment?
}
