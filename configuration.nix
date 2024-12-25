{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

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
    kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;
    # Bootloader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_zen;
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
    fstrim.enable = true;

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

    desktopManager.cosmic.enable = true;
    displayManager.cosmic-greeter.enable = true;

    # List services that you want to enable:
    openssh.enable = true;
    fail2ban.enable = true;
  };

  security.rtkit.enable = true;
  users = {
    users.jwilger = {
      isNormalUser = true;
      description = "John Wilger";
      extraGroups = ["networkmanager" "wheel" "docker"];
      shell = pkgs.zsh;
      home = "/home/jwilger";
      group = "jwilger";
      createHome = true;
    };

    groups.jwilger = {};
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    home-manager
    docker-client
    catppuccin
    catppuccin-cursors
    neovim
    pipewire
    wireplumber
    grim
    slurp
    solaar
    firefoxpwa
  ];

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
