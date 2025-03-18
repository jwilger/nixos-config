{pkgs, ...}: 
{
  # Never change this. Ever.
  system.stateVersion = "24.11"; # Did you read the comment?
  
  imports = [
    ./hardware-configuration.nix
  ];
  
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

  hardware = {
    graphics = {
      package = pkgs.mesa;
      package32 = pkgs.pkgsi686Linux.mesa;
      enable32Bit = true;
    };
    
    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };
  
  boot = {
    kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;
    # Bootloader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
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

  stylix = {
    enable = true;
    image = ./wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
    polarity = "dark";
  };


  security = {
    rtkit.enable = true;
    pam.services.greetd.enableGnomeKeyring = true;
  };
  
  environment.systemPackages = with pkgs; [
    git
    git-crypt
    home-manager
    hyprcursor
    hyprpolkitagent
    pavucontrol
    pipewire
    unzip
    wireplumber
  ];

  fonts = {
  fontconfig.useEmbeddedBitmaps = true;
  packages = with pkgs; [
    material-design-icons
    powerline-fonts
    powerline-symbols
    noto-fonts-color-emoji
    font-awesome
    nerd-fonts.jetbrains-mono
  ];
  };

  
  programs = {
    hyprland.enable = true;
    hyprlock.enable = true;
    mtr.enable = true;
    zsh.enable = true;
    
    nix-ld = {
      enable = true;
    };

  };

  services = {
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

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time";
          user = "greeter";
        };
      };
      restart = true;
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
    
  networking = {
    hostName = "gregor"; # Define your hostname.
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 ];
    };
  };
  
  users = {
    users.jwilger = {
      isNormalUser = true;
      description = "John Wilger";
      extraGroups = ["wheel" "docker"];
      shell = pkgs.zsh;
      home = "/home/jwilger";
      group = "jwilger";
      createHome = true;
    };
    groups.jwilger = {};
  };
}
