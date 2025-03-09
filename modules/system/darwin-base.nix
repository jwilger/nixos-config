# Common system-wide settings for macOS
{ pkgs, ... }:

{
  # Basic Darwin configuration
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; }; # Weekly on Sunday at 2am
      options = "--delete-older-than 30d";
    };
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      trusted-users = root jwilger
    '';
  };

  nixpkgs.config.allowUnfree = true;

  # Darwin-specific services
  services = {
    nix-daemon.enable = true;
    activate-system.enable = true;
  };
  
  # Time zone settings
  time.timeZone = "America/Los_Angeles";

  # Environment setup
  environment = {
    systemPackages = with pkgs; [
      # Common system utilities
      coreutils
      curl
      wget
      git
    ];
    shells = with pkgs; [ zsh bash ];
    loginShell = pkgs.zsh;
    variables = {
      LANG = "en_US.UTF-8";
      EDITOR = "vim";
    };
  };

  # Font configuration
  fonts.fonts = with pkgs; [
    material-design-icons
    powerline-fonts
    powerline-symbols
    noto-fonts-color-emoji
    font-awesome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # Programs
  programs.zsh.enable = true;
}