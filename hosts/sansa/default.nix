{ config, pkgs, lib, ... }:

{
  # macOS-specific configuration for sansa
  networking = {
    hostName = "sansa"; # Define hostname
    # Note: networkmanager is not applicable on macOS
  };

  # macOS-specific user configuration
  users.users = {
    jwilger = {
      home = "/Users/jwilger";
      description = "John Wilger";
      # No need for extraGroups on macOS
    };
  };

  # macOS-specific system packages
  # These will be installed via nix-darwin/home-manager
  environment.systemPackages = with pkgs; [
    # Basic system utilities
    # Most packages will be managed through home-manager
  ];

  # macOS-specific settings
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark"; # Dark mode
      AppleKeyboardUIMode = 3; # Full keyboard control
      AppleShowAllExtensions = true; # Show all file extensions
      AppleShowScrollBars = "Always";
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
    };
    
    dock = {
      autohide = true;
      minimize-to-application = true;
      mru-spaces = false;
      show-recents = false;
      tilesize = 48;
    };
    
    finder = {
      AppleShowAllExtensions = true;
      QuitMenuItem = true;
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
    };
  };
}
