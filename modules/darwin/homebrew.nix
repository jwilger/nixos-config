{ ... }:
{
  # Homebrew declarative configuration
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    global = {
      brewfile = true;
    };

    # Taps (third-party repositories)
    taps = [
      "homebrew/cask"
      "homebrew/cask-versions"
      "homebrew/services"
      "nikitabobko/tap" # For AeroSpace window manager
    ];

    # Formulae (CLI tools)
    brews = [
      # Development tools that work better via Homebrew on macOS
    ];

    # Casks (GUI applications)
    casks = [
      # Window Management
      "aerospace" # Tiling window manager (alternative to Rectangle)

      # Utilities
      "caffeine" # Prevent Mac from sleeping
      "iterm2" # Terminal emulator
      "tuple" # Pair programming tool

      # Browsers
      "firefox"

      # Communication
      "slack"
      "zoom"

      # Media
      "spotify"
      "vlc"

      # Development
      "docker"

      # Password Management
      "1password"
      "1password-cli"
    ];

    # Mac App Store apps (requires mas-cli)
    masApps = {
      # Add Mac App Store apps here if needed
      # Example: "Xcode" = 497799835;
    };
  };
}
