# Common system-wide settings for macOS
{ pkgs, ... }:

{
  system.stateVersion = 6;

  # Basic Darwin configuration
  nix = {
    optimise.automatic = true;
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
    variables = {
      LANG = "en_US.UTF-8";
      EDITOR = "vim";
    };
  };

  # Font configuration
  fonts.packages = with pkgs; [
    material-design-icons
    powerline-fonts
    powerline-symbols
    noto-fonts-color-emoji
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  # Programs
  programs.zsh.enable = true;
}
